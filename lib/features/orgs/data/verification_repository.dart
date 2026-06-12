import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/models/verification_models.dart';
import '../../../core/network/api_client.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.read(apiClientProvider));
});

final verificationTypesProvider =
    FutureProvider.family.autoDispose<List<VerificationTypeDefinition>, String>(
      (ref, category) async {
        final VerificationRepository repo = ref.read(
          verificationRepositoryProvider,
        );
        final List<String> parts = category.split('::');
        final String normalizedCategory = parts.isNotEmpty
            ? parts.first.trim()
            : '';
        final String rawIndustryTypes = parts.length > 1
            ? parts.sublist(1).join('::').trim()
            : '';
        final List<String> industryTypes = () {
          if (rawIndustryTypes.isEmpty) return const <String>[];
          if (rawIndustryTypes.startsWith('[')) {
            try {
              final dynamic decoded = jsonDecode(rawIndustryTypes);
              if (decoded is List) {
                return decoded
                    .map((dynamic e) => e?.toString().trim() ?? '')
                    .where((String s) => s.isNotEmpty)
                    .toList();
              }
            } catch (_) {
              // Fall through to comma-separated parsing.
            }
          }
          return rawIndustryTypes
              .split(',')
              .map((String s) => s.trim())
              .where((String s) => s.isNotEmpty)
              .toList();
        }();
        return repo.getVerificationTypes(
          category: normalizedCategory,
          industryTypes: industryTypes.isEmpty ? null : industryTypes,
        );
      },
    );

class VerificationRepository {
  VerificationRepository(this._api);

  final ApiClient _api;

  Future<List<VerificationTypeDefinition>> getVerificationTypes({
    String? category,
    List<String>? industryTypes,
  }) async {
    final Map<String, dynamic> queryParameters = <String, dynamic>{};
    if (category != null && category.trim().isNotEmpty) {
      queryParameters['category'] = category.trim();
    }
    if (industryTypes != null && industryTypes.isNotEmpty) {
      queryParameters['industry_type'] = jsonEncode(industryTypes);
    }
    final dynamic res = await _api.verificationGetAny(
      '/verification/verification-types',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    Iterable<dynamic> rawItems;
    if (res is List) {
      rawItems = res;
    } else if (res is Map) {
      final dynamic data = res['data'] ?? res['verification_types'] ?? res['types'];
      rawItems = data is List ? data : const <dynamic>[];
    } else {
      rawItems = const <dynamic>[];
    }

    final String normalizedCategory = category?.trim().toLowerCase() ?? '';
    return rawItems
        .whereType<Map>()
        .map(
          (Map e) =>
              VerificationTypeDefinition.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((VerificationTypeDefinition item) {
          if (normalizedCategory.isEmpty) return true;
          return item.category.trim().toLowerCase() == normalizedCategory;
        })
        .toList();
  }

  Future<List<VerificationCategory>> getProductCategories() async {
    final dynamic res = await _api.verificationGetAny(
      '/verification/categories',
    );
    if (res is List) {
      return res
          .whereType<Map>()
          .map(
            (Map e) =>
                VerificationCategory.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    // Some backends wrap arrays in {data:[...]}.
    if (res is Map) {
      final dynamic data = res['data'] ?? res['categories'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (Map e) =>
                  VerificationCategory.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    }
    return const <VerificationCategory>[];
  }

  Future<SingleProductUploadResponse> uploadSingleProduct({
    required String categoryId,
    required String productName,
    Map<String, dynamic>? customFields,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/single/product',
      data: <String, dynamic>{
        'category_id': categoryId.trim(),
        'product_name': productName.trim(),
        if (customFields != null && customFields.isNotEmpty)
          'custom_fields': customFields,
      },
    );
    return SingleProductUploadResponse.fromJson(res);
  }

  Future<BulkUploadResponse> bulkUploadProducts({
    required String batchName,
    required String categoryId,
    String? description,
    String? industryType,
    String? verificationTypes,
    String? credentialVisibility,
    String? templateId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'upload.xlsx' : fileName;
    final String ext = safeName.split('.').last.toLowerCase();
    final MediaType contentType = switch (ext) {
      'csv' => MediaType('text', 'csv'),
      'xls' => MediaType('application', 'vnd.ms-excel'),
      _ => MediaType(
        'application',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    };
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      'category_id': categoryId.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (industryType != null && industryType.trim().isNotEmpty)
        'industry_type': industryType.trim(),
      if (verificationTypes != null && verificationTypes.trim().isNotEmpty)
        'verification_types': verificationTypes.trim(),
      if (credentialVisibility != null &&
          credentialVisibility.trim().isNotEmpty)
        'credential_visibility': credentialVisibility.trim(),
      if (templateId != null && templateId.trim().isNotEmpty)
        'template_id': templateId.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/bulk-upload/products',
      formData,
    );
    return BulkUploadResponse.fromJson(res);
  }

  Future<VerificationBinaryResponse> generateProductsTemplate({
    required String categoryId,
    required List<String> headers,
  }) async {
    final List<String> cleanHeaders = headers
        .map((String h) => h.trim())
        .where((String h) => h.isNotEmpty)
        .toList();
    final String headersCsv = cleanHeaders.join(',');
    return _api.verificationPostFormUrlEncodedBinary(
      '/verification/products/template',
      data: <String, dynamic>{
        'category_id': categoryId.trim(),
        // Backend expects a string in x-www-form-urlencoded.
        'headers': headersCsv,
      },
    );
  }

  Future<VerificationBinaryResponse> generateHumanTemplate({
    required String headers,
    required String verificationTypes,
  }) async {
    return _api.verificationPostFormUrlEncodedBinary(
      '/verification/generate-human-template',
      data: <String, dynamic>{
        'headers': headers.trim(),
        if (verificationTypes.trim().isNotEmpty)
          'verification_types': verificationTypes.trim(),
      },
    );
  }

  Future<SingleHumanUploadResponse> uploadSingleHuman({
    required String fullName,
    required String phoneNumber,
    required String email,
    String? dob,
    String? aadharNumber,
    String? panNumber,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? pincode,
    String? state,
    String? country,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/single/human',
      data: <String, dynamic>{
        'full_name': fullName.trim(),
        if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
        'phone_number': phoneNumber.trim(),
        'email': email.trim(),
        if (aadharNumber != null && aadharNumber.trim().isNotEmpty)
          'aadhar_number': aadharNumber.trim(),
        if (panNumber != null && panNumber.trim().isNotEmpty)
          'pan_number': panNumber.trim(),
        if (addressLine1 != null && addressLine1.trim().isNotEmpty)
          'address_line1': addressLine1.trim(),
        if (addressLine2 != null && addressLine2.trim().isNotEmpty)
          'address_line2': addressLine2.trim(),
        if (addressLine3 != null && addressLine3.trim().isNotEmpty)
          'address_line3': addressLine3.trim(),
        if (pincode != null && pincode.trim().isNotEmpty)
          'pincode': pincode.trim(),
        if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
        if (country != null && country.trim().isNotEmpty)
          'country': country.trim(),
      },
    );
    return SingleHumanUploadResponse.fromJson(res);
  }

  Future<BulkUploadResponse> bulkUpload({
    required String batchName,
    String? description,
    String? industryType,
    String? verificationTypes,
    String? credentialVisibility,
    String? templateId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'upload.xlsx' : fileName;
    final String ext = safeName.split('.').last.toLowerCase();
    final MediaType contentType = switch (ext) {
      'csv' => MediaType('text', 'csv'),
      'xls' => MediaType('application', 'vnd.ms-excel'),
      _ => MediaType(
        'application',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    };
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (industryType != null && industryType.trim().isNotEmpty)
        'industry_type': industryType.trim(),
      if (verificationTypes != null && verificationTypes.trim().isNotEmpty)
        'verification_types': verificationTypes.trim(),
      if (credentialVisibility != null &&
          credentialVisibility.trim().isNotEmpty)
        'credential_visibility': credentialVisibility.trim(),
      if (templateId != null && templateId.trim().isNotEmpty)
        'template_id': templateId.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/bulk-upload',
      formData,
    );
    return BulkUploadResponse.fromJson(res);
  }

  Future<VerificationListResponse> getAllVerifications({
    String? orgId,
    String? batchId,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    final Map<String, String> qp = <String, String>{
      if (orgId != null && orgId.trim().isNotEmpty) 'org_id': orgId.trim(),
      if (batchId != null && batchId.trim().isNotEmpty)
        'batch_id': batchId.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    final Uri uri = Uri(path: '/verification/all', queryParameters: qp);
    final Map<String, dynamic> res = await _api.verificationGet(uri.toString());
    return VerificationListResponse.fromJson(res);
  }

  Future<VerificationUser> getUserVerification(String userId) async {
    final Map<String, dynamic> res = await _api.verificationGet(
      '/verification/user/${Uri.encodeComponent(userId)}',
    );
    return VerificationUser.fromJson(res);
  }

  Future<void> updateVerificationStatus({
    required String userId,
    required String status, // 'verified' | 'failed' | 'pending_verification'
    String? reason,
  }) async {
    await _api.verificationPatch(
      '/verification/user/${Uri.encodeComponent(userId)}/status',
      data: <String, dynamic>{
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<GenerateCertificateResponse> generateCertificate(String userId) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/user/${Uri.encodeComponent(userId)}/generate-qr',
      data: const <String, dynamic>{},
    );
    return GenerateCertificateResponse.fromJson(res);
  }

  Future<UploadPhotoResponse> uploadPhoto({
    required String inviteToken,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'token': inviteToken,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/upload/photo',
      formData,
      skipAuth: true,
    );
    return UploadPhotoResponse.fromJson(res);
  }

  Future<UploadDocumentResponse> uploadDocument({
    required String inviteToken,
    required String documentLabel,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'token': inviteToken,
      'document_label': documentLabel,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/upload/document',
      formData,
      skipAuth: true,
    );
    return UploadDocumentResponse.fromJson(res);
  }
}
