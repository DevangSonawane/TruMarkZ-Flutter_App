import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/models/verification_models.dart';
import '../../../core/network/api_client.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.read(apiClientProvider));
});

class VerificationRepository {
  VerificationRepository(this._api);

  final ApiClient _api;

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
    String? description,
    required String categoryId,
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
      'batch_name': batchName,
      'category_id': categoryId.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
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

  Future<String> generateProductsTemplate({
    required String categoryId,
    required List<String> headers,
  }) async {
    final List<String> cleanHeaders = headers
        .map((String h) => h.trim())
        .where((String h) => h.isNotEmpty)
        .toList();
    final String template = await _api.verificationPostFormUrlEncodedString(
      '/verification/products/template',
      data: <String, dynamic>{
        'category_id': categoryId.trim(),
        'headers': cleanHeaders,
      },
    );
    return template.trim();
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
      'batch_name': batchName,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
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
