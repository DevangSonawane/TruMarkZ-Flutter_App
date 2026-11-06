import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../services/token_storage.dart';
import '../utils/field_text.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const <String>[],
    this.errorId,
    this.detail,
  });

  final int? statusCode;

  /// Display-ready text. When the backend returns an object `detail`
  /// (`{"message": ..., "errors": [...]}`) the errors are appended as bullets.
  final String message;

  /// Individual entries from an object `detail.errors` (or a top-level
  /// `errors` list on schema-config 400s). Empty for string `detail`.
  final List<String> errors;

  /// `error_id` from a JSON 500 body, for support lookups.
  final String? errorId;

  /// Structured backend detail, used when errors belong to individual rows.
  final Map<String, dynamic>? detail;

  /// True for the schema-selection 400s (unknown or ambiguous
  /// `schema_name`): the cached schema list is stale and should be re-fetched.
  bool get isStaleSchemaSelection {
    if (statusCode != 400) return false;
    final String m = message.toLowerCase();
    return (m.contains('no active') && m.contains('schema named')) ||
        (m.contains('more than one active') && m.contains('schema is named'));
  }

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
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
          headers: <String, dynamic>{
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      ),
      _verificationDio = Dio(
        BaseOptions(
          // Use the Cloud Run base as source-of-truth for verification APIs.
          // The custom domain can fail intermittently (DNS/TLS) on some networks.
          baseUrl: 'https://trumarkz-api-54038467488.asia-south1.run.app',
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
          headers: <String, dynamic>{
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      ) {
    _configureDio(_dio);
    _configureDio(_verificationDio);

    if (kDebugMode) {
      // Keep this lightweight: multipart bodies can be huge.
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: false,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (Object o) => debugPrint(o.toString()),
        ),
      );
      _verificationDio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: false,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (Object o) => debugPrint(o.toString()),
        ),
      );
    }
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

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        path,
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': skipAuth},
        ),
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
      final Response<dynamic> res = await _dio.patch<dynamic>(
        path,
        data: data,
        options: Options(contentType: Headers.jsonContentType),
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

  Future<dynamic> deleteAny(String path, {Object? data}) async {
    try {
      final Response<dynamic> res = await _dio.delete<dynamic>(
        path,
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      );
      return res.data;
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
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Response<dynamic> res = await _dio.get<dynamic>(path);
          return _asMap(res.data);
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<VerificationBinaryResponse> verificationGetBinary(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> res = await _verificationDio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      return VerificationBinaryResponse(
        bytes: _asBytes(res.data),
        contentDisposition: res.headers.value('content-disposition'),
      );
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Response<dynamic> res = await _dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
            options: Options(responseType: ResponseType.bytes),
          );
          return VerificationBinaryResponse(
            bytes: _asBytes(res.data),
            contentDisposition: res.headers.value('content-disposition'),
          );
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // For endpoints that return a JSON array (or non-map JSON).
  Future<dynamic> verificationGetAny(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> res = await _verificationDio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return res.data;
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Response<dynamic> res = await _dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
          );
          return res.data;
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
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
    bool skipAuth = false,
  }) async {
    try {
      final Response<dynamic> res = await _verificationDio.post<dynamic>(
        path,
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: skipAuth ? <String, dynamic>{'skipAuth': true} : null,
        ),
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Response<dynamic> res = await _dio.post<dynamic>(
            path,
            data: data,
            options: Options(
              contentType: Headers.jsonContentType,
              extra: skipAuth ? <String, dynamic>{'skipAuth': true} : null,
            ),
          );
          return _asMap(res.data);
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<String> verificationPostFormUrlEncodedString(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final Options options = Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      );
      final Response<dynamic> res = await _verificationDio.post<dynamic>(
        path,
        data: data,
        options: options,
      );
      return _asString(res.data);
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Options retryOptions = Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.plain,
          );
          final Response<dynamic> res = await _dio.post<dynamic>(
            path,
            data: data,
            options: retryOptions,
          );
          return _asString(res.data);
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<VerificationBinaryResponse> verificationPostFormUrlEncodedBinary(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final Options options = Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.bytes,
      );
      final Response<dynamic> res = await _verificationDio.post<dynamic>(
        path,
        data: data,
        options: options,
      );
      return VerificationBinaryResponse(
        bytes: _asBytes(res.data),
        contentDisposition: res.headers.value('content-disposition'),
      );
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Options retryOptions = Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.bytes,
          );
          final Response<dynamic> res = await _dio.post<dynamic>(
            path,
            data: data,
            options: retryOptions,
          );
          return VerificationBinaryResponse(
            bytes: _asBytes(res.data),
            contentDisposition: res.headers.value('content-disposition'),
          );
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
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
        options: Options(contentType: Headers.jsonContentType),
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Response<dynamic> res = await _dio.patch<dynamic>(
            path,
            data: data,
            options: Options(contentType: Headers.jsonContentType),
          );
          return _asMap(res.data);
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<Map<String, dynamic>> verificationPut(
    String path, {
    Object? data,
  }) async {
    try {
      final Response<dynamic> res = await _verificationDio.put<dynamic>(
        path,
        data: data,
        options: Options(contentType: Headers.jsonContentType),
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

  /// True when [uri] points at the TruMarkZ API, i.e. it is safe to attach
  /// the organization's Bearer session to it.
  bool isApiUrl(Uri uri) {
    final String host = uri.host.toLowerCase();
    if (host.isEmpty || uri.scheme != 'https') return false;
    return host == Uri.parse(_verificationDio.options.baseUrl).host ||
        host == Uri.parse(_dio.options.baseUrl).host;
  }

  /// Downloads an absolute TruMarkZ API URL (e.g. a report link) with the
  /// organization session. Gated (`holder_approval`) reports return 403 to
  /// unauthenticated browsers, so they must be fetched this way.
  Future<VerificationBinaryResponse> verificationGetBinaryUrl(Uri uri) async {
    if (!isApiUrl(uri)) {
      throw const ApiException(
        statusCode: null,
        message: 'This link is not a TruMarkZ report.',
      );
    }
    try {
      final Response<dynamic> res = await _verificationDio.getUri<dynamic>(
        uri,
        options: Options(responseType: ResponseType.bytes),
      );
      return VerificationBinaryResponse(
        bytes: _asBytes(res.data),
        contentDisposition: res.headers.value('content-disposition'),
        contentType: res.headers.value(Headers.contentTypeHeader),
      );
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
      final Options options = Options(
        extra: skipAuth ? <String, dynamic>{'skipAuth': true} : null,
      );
      final Response<dynamic> res = await _verificationDio.post<dynamic>(
        path,
        data: formData,
        options: options,
      );
      return _asMap(res.data);
    } on DioException catch (e) {
      if (_shouldRetryOnPrimary(e)) {
        try {
          final Options retryOptions = Options(
            extra: skipAuth ? <String, dynamic>{'skipAuth': true} : null,
          );
          final Response<dynamic> res = await _dio.post<dynamic>(
            path,
            data: formData,
            options: retryOptions,
          );
          return _asMap(res.data);
        } on DioException catch (e2) {
          throw _toApiException(e2);
        }
      }
      throw _toApiException(e);
    } catch (_) {
      throw const ApiException(
        statusCode: null,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  bool _shouldRetryOnPrimary(DioException e) {
    // Kept for backward-compat, but verification baseUrl already points to
    // Cloud Run. Only retry on transient network layer errors.
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.badCertificate;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String _asString(dynamic data) {
    if (data == null) return '';
    if (data is String) {
      final String raw = data.trim();
      // Some backends return a JSON string (quoted) even with plain responseType.
      if (raw.startsWith('"') && raw.endsWith('"') && raw.length >= 2) {
        return raw.substring(1, raw.length - 1);
      }
      return raw;
    }
    return data.toString();
  }

  Uint8List _asBytes(dynamic data) {
    if (data == null) return Uint8List(0);
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    if (data is List) {
      return Uint8List.fromList(
        data.map((dynamic e) => (e as num).toInt()).toList(),
      );
    }
    if (data is String) return Uint8List.fromList(data.codeUnits);
    return Uint8List.fromList(data.toString().codeUnits);
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
          final bool skipAuth = err.requestOptions.extra['skipAuth'] == true;
          if (kDebugMode) {
            debugPrint(
              '[ApiClient] error ${err.requestOptions.method} ${err.requestOptions.uri} '
              'status=$statusCode type=${err.type} message=${err.message} error=${err.error} data=${err.response?.data}',
            );
          }
          if (statusCode == 401 && !skipAuth) {
            await _tokenStorage.clearAll();
            scheduleMicrotask(
              () => AppRouter.router.go(AppRouter.onboardingPath),
            );
            handler.next(err);
            return;
          }

          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              response: err.response,
              type: err.type,
              error: _buildApiException(err),
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
    return _buildApiException(e);
  }

  ApiException _buildApiException(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final List<String> errors = _extractErrorList(
      e,
    ).map(friendlyFieldText).toList();
    final String? errorId = _extractErrorId(e);
    final String? extracted = _extractErrorMessage(e);
    String message =
        (extracted == null ? null : friendlyFieldText(extracted)) ??
        _fallbackMessageForType(e.type) ??
        (statusCode != null
            ? 'Request failed ($statusCode). Please try again.'
            : 'Something went wrong. Please try again.');
    final dynamic body = e.response?.data;
    final bool genericServerError =
        statusCode == 500 &&
        (errorId != null ||
            body is String ||
            message.toLowerCase() == 'internal server error');
    if (genericServerError) {
      // JSON 500s are {"detail": "Internal server error", "error_id": ...};
      // older revisions return a plain-text body. Never surface raw bodies.
      message = 'Something went wrong on our side. Please try again.';
      if (errorId != null) message = '$message (Error ID: $errorId)';
    } else if (errors.isNotEmpty) {
      message = <String>[
        message,
        ...errors.map((String error) => '• $error'),
      ].join('\n');
    }
    return ApiException(
      statusCode: statusCode,
      message: message,
      errors: errors,
      errorId: errorId,
      detail: body is Map && body['detail'] is Map
          ? Map<String, dynamic>.from(body['detail'] as Map)
          : null,
    );
  }

  List<String> _extractErrorList(DioException err) {
    final dynamic data = err.response?.data;
    if (data is! Map) return const <String>[];
    final dynamic detail = data['detail'];
    final dynamic raw = detail is Map ? detail['errors'] : data['errors'];
    if (raw is! List) return const <String>[];
    return raw
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  String? _extractErrorId(DioException err) {
    final dynamic data = err.response?.data;
    if (data is! Map) return null;
    final dynamic id = data['error_id'];
    if (id is String && id.trim().isNotEmpty) return id.trim();
    return null;
  }

  String? _fallbackMessageForType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your connection and try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled. Please try again.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return null;
    }
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
          if (msg is String && msg.trim().isNotEmpty) {
            // FastAPI validation errors name the field in `loc`; say which
            // field it is when the message itself doesn't.
            final dynamic loc = m['loc'];
            final String field = loc is List && loc.isNotEmpty
                ? loc.last.toString()
                : '';
            if (field == 'phone_number' && !msg.contains('phone')) {
              return 'Phone number: ${msg.trim()}';
            }
            return msg.trim();
          }
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

class VerificationBinaryResponse {
  const VerificationBinaryResponse({
    required this.bytes,
    this.contentDisposition,
    this.contentType,
  });

  final Uint8List bytes;
  final String? contentDisposition;
  final String? contentType;

  /// Filename from Content-Disposition, or null when the header has none.
  String? get dispositionFilename {
    final String? disposition = contentDisposition;
    if (disposition == null || disposition.trim().isEmpty) return null;
    final Match? match = RegExp(
      r'filename="?([^\";]+)"?',
    ).firstMatch(disposition);
    final String? name = match?.group(1)?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  String get filename {
    final String? disposition = contentDisposition;
    if (disposition == null || disposition.trim().isEmpty) {
      return 'human_template.xlsx';
    }
    final RegExp quoted = RegExp(r'filename="?([^\";]+)"?');
    final Match? match = quoted.firstMatch(disposition);
    if (match != null) return match.group(1)!.trim();
    return 'human_template.xlsx';
  }
}
