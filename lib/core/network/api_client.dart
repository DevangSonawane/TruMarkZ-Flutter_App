import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../services/token_storage.dart';

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.read(tokenStorageProvider));
});

class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://trumarkz-api-54038467488.asia-south1.run.app',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: <String, dynamic>{
            Headers.contentTypeHeader: Headers.jsonContentType,
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      ),
      _verificationDio = Dio(
        BaseOptions(
          baseUrl: 'https://trumarkz-api.asynk.in',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: <String, dynamic>{
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      ) {
    _configureDio(_dio);
    _configureDio(_verificationDio);
  }

  final Dio _dio;
  final Dio _verificationDio;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(path);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(path, data: data);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // For multipart (file upload) requests — no Content-Type override, let Dio set boundary
  Future<Map<String, dynamic>> postMultipart(
    String path,
    FormData formData,
  ) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        path,
        data: formData,
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // For PATCH requests
  Future<Map<String, dynamic>> patch(String path, {Object? data}) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(path, data: data);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> verificationGet(String path) async {
    try {
      final Response<dynamic> res = await _verificationDio.get<dynamic>(path);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> verificationPost(
    String path, {
    Object? data,
  }) async {
    try {
      final Response<dynamic> res = await _verificationDio.post<dynamic>(
        path,
        data: data,
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> verificationPatch(
    String path, {
    Object? data,
  }) async {
    try {
      final Response<dynamic> res = await _verificationDio.patch<dynamic>(
        path,
        data: data,
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> verificationPostMultipart(
    String path,
    FormData formData, {
    bool skipAuth = false,
  }) async {
    try {
      final Options? options = skipAuth
          ? Options(extra: <String, dynamic>{'skipAuth': true})
          : null;
      final Response<dynamic> res = await _verificationDio.post<dynamic>(
        path,
        data: formData,
        options: options,
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  void _configureDio(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final bool skipAuth = options.extra['skipAuth'] == true;
              if (!skipAuth) {
                final String? token = await _tokenStorage.getToken();
                if (token != null && token.trim().isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }
              handler.next(options);
            },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final int? statusCode = err.response?.statusCode;
          if (statusCode == 401) {
            await _tokenStorage.clearAll();
            scheduleMicrotask(
              () => AppRouter.router.go(AppRouter.roleSelectionPath),
            );
            handler.next(err);
            return;
          }

          final String message =
              _extractErrorMessage(err) ??
              'Something went wrong. Please try again.';
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              response: err.response,
              type: err.type,
              error: ApiException(statusCode: statusCode, message: message),
              stackTrace: err.stackTrace,
              message: err.message,
            ),
          );
        },
      ),
    );
  }

  ApiException _toApiException(DioException e) {
    final Object? inner = e.error;
    if (inner is ApiException) return inner;
    final int? statusCode = e.response?.statusCode;
    final String message =
        _extractErrorMessage(e) ?? 'Something went wrong. Please try again.';
    return ApiException(statusCode: statusCode, message: message);
  }

  String? _extractErrorMessage(DioException err) {
    final dynamic data = err.response?.data;
    if (data is Map) {
      final dynamic detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is List && detail.isNotEmpty) {
        final dynamic first = detail.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
        if (first is Map) {
          final Map<String, dynamic> m = Map<String, dynamic>.from(first);
          final dynamic msg = m['msg'] ?? m['message'] ?? m['detail'];
          if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        }
      }
      if (detail is Map) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(detail);
        final dynamic msg = m['message'] ?? m['detail'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      final dynamic message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
