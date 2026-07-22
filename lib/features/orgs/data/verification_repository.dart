import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/models/verification_models.dart';
import '../../../core/network/api_client.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.read(apiClientProvider));
});

final verificationBatchesProvider =
    FutureProvider.autoDispose<List<VerificationBatchSummary>>((ref) async {
      return ref.read(verificationRepositoryProvider).getBatches();
    });

final verificationTypesProvider = FutureProvider.family
    .autoDispose<List<VerificationTypeDefinition>, String>((
      ref,
      category,
    ) async {
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
    });

class ProductBulkUploadDocumentInput {
  const ProductBulkUploadDocumentInput({
    required this.productName,
    required this.label,
    required this.fileBytes,
    required this.fileName,
  });

  final String productName;
  final String label;
  final Uint8List fileBytes;
  final String fileName;
}

class VerificationRepository {
  VerificationRepository(this._api);

  final ApiClient _api;

  static MediaType _mediaTypeForFileName(String fileName) {
    final String safeName = fileName.trim().isEmpty ? 'upload.xlsx' : fileName;
    final String ext = safeName.split('.').last.toLowerCase();
    return switch (ext) {
      'csv' => MediaType('text', 'csv'),
      'xls' => MediaType('application', 'vnd.ms-excel'),
      'pdf' => MediaType('application', 'pdf'),
      'png' => MediaType('image', 'png'),
      'jpg' => MediaType('image', 'jpeg'),
      'jpeg' => MediaType('image', 'jpeg'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType(
        'application',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    };
  }

  Future<List<VerificationTypeDefinition>> getVerificationTypes({
    String? category,
    List<String>? industryTypes,
  }) async {
    final Map<String, dynamic> queryParameters = <String, dynamic>{};
    if (category != null && category.trim().isNotEmpty) {
      queryParameters['category'] = category.trim();
    }
    if (industryTypes != null && industryTypes.isNotEmpty) {
      queryParameters['industry_type'] = industryTypes.first.trim();
    }
    final dynamic res = await _api.verificationGetAny(
      '/verification/verification-types',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    Iterable<dynamic> rawItems;
    if (res is List) {
      rawItems = res;
    } else if (res is Map) {
      final dynamic data =
          res['data'] ?? res['verification_types'] ?? res['types'];
      rawItems = data is List ? data : const <dynamic>[];
    } else {
      rawItems = const <dynamic>[];
    }

    final String normalizedCategory = category?.trim().toLowerCase() ?? '';
    final String normalizedIndustry = industryTypes?.isNotEmpty == true
        ? industryTypes!.first.trim().toLowerCase()
        : '';
    return rawItems
        .whereType<Map>()
        .map(
          (Map e) =>
              VerificationTypeDefinition.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((VerificationTypeDefinition item) {
          if (normalizedCategory.isEmpty) return true;
          final bool matchesCategory =
              item.category.trim().toLowerCase() == normalizedCategory;
          if (!matchesCategory) return false;
          if (normalizedIndustry.isEmpty) return true;
          final Set<String> itemIndustries = item.industryTypes
              .map((String value) => value.trim().toLowerCase())
              .where((String value) => value.isNotEmpty)
              .toSet();
          if (itemIndustries.isEmpty) return true;
          return itemIndustries.contains(normalizedIndustry);
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

  Future<List<VerificationIndustryType>> getIndustryTypes() async {
    final dynamic res = await _api.verificationGetAny(
      '/verification/industry-types',
    );
    Iterable<dynamic> rawItems;
    if (res is List) {
      rawItems = res;
    } else if (res is Map) {
      final dynamic data = res['data'] ?? res['industry_types'] ?? res['types'];
      rawItems = data is List ? data : const <dynamic>[];
    } else {
      rawItems = const <dynamic>[];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (Map e) =>
              VerificationIndustryType.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((VerificationIndustryType item) => item.name.trim().isNotEmpty)
        .toList();
  }

  Future<List<VerificationBatchSummary>> getBatches() async {
    final dynamic res = await _api.verificationGetAny('/verification/batches');
    final List<VerificationBatchSummary> batches = <VerificationBatchSummary>[];

    void addBatchesFrom(dynamic value) {
      if (value is List) {
        for (final dynamic item in value) {
          if (item is Map) {
            final Map<String, dynamic> json = Map<String, dynamic>.from(item);
            if (json['batches'] is List) {
              batches.addAll(VerificationBatchGroup.fromJson(json).batches);
            } else {
              final VerificationBatchSummary summary =
                  VerificationBatchSummary.fromJson(json);
              if (summary.batchId.isNotEmpty) {
                batches.add(summary);
              }
            }
          }
        }
      } else if (value is Map) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(value);
        if (json['batches'] is List) {
          batches.addAll(VerificationBatchGroup.fromJson(json).batches);
        } else if (json['data'] is List) {
          addBatchesFrom(json['data']);
        }
      }
    }

    addBatchesFrom(res);

    batches.sort((VerificationBatchSummary a, VerificationBatchSummary b) {
      final DateTime? da = DateTime.tryParse(a.createdAt);
      final DateTime? db = DateTime.tryParse(b.createdAt);
      if (da == null && db == null) {
        return b.batchName.compareTo(a.batchName);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return batches;
  }

  Future<SdcRecordsResponse> getSdcRecords({
    String? orgId,
    String? spaceId,
    int active = 1,
    int page = 1,
    int pageSize = 30,
    String search = '',
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      if (orgId != null && orgId.trim().isNotEmpty) 'org_id': orgId.trim(),
      if (spaceId != null && spaceId.trim().isNotEmpty)
        'space_id': spaceId.trim(),
      'active': active.toString(),
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    debugPrint(
      '[verification-repo] GET /sdc/records orgId=${queryParameters['org_id']} spaceId=${queryParameters['space_id']} active=${queryParameters['active']} page=${queryParameters['page']} pageSize=${queryParameters['pageSize']} search=${queryParameters['search'] ?? ''}',
    );
    final dynamic res = await _api.verificationGetAny(
      '/sdc/records',
      queryParameters: queryParameters,
    );
    if (res is Map<String, dynamic>) {
      return SdcRecordsResponse.fromJson(res);
    }
    if (res is Map) {
      return SdcRecordsResponse.fromJson(Map<String, dynamic>.from(res));
    }
    debugPrint('[verification-repo] GET /sdc/records returned non-map payload');
    return SdcRecordsResponse.fromJson(<String, dynamic>{
      'count': 0,
      'page': page,
      'pageSize': pageSize,
      'records': const <dynamic>[],
      'instanceKey': '',
    });
  }

  Future<SdcRecordDetailResponse> getSdcRecord({
    required String publicId,
    String instanceKey = 'de',
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      'instance_key': instanceKey.trim().isEmpty ? 'de' : instanceKey.trim(),
    };
    debugPrint(
      '[verification-repo] GET /sdc/records/$publicId instanceKey=${queryParameters['instance_key']}',
    );
    final dynamic res = await _api.verificationGetAny(
      '/sdc/records/${Uri.encodeComponent(publicId.trim())}',
      queryParameters: queryParameters,
    );
    if (res is Map<String, dynamic>) {
      return SdcRecordDetailResponse.fromJson(res);
    }
    if (res is Map) {
      return SdcRecordDetailResponse.fromJson(Map<String, dynamic>.from(res));
    }
    return SdcRecordDetailResponse.fromJson(<String, dynamic>{
      'public_id': publicId.trim(),
      'pdf': '',
      'verify': '',
      'credential': null,
    });
  }

  Future<VerificationBatchDetailResponse> getBatchDetails(
    String batchId,
  ) async {
    final Map<String, dynamic> res = await _api.verificationGet(
      '/verification/batches/${Uri.encodeComponent(batchId.trim())}',
    );
    return VerificationBatchDetailResponse.fromJson(res);
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
    String? description,
    String? industryType,
    String? verificationTypes,
    List<ProductBulkUploadDocumentInput> documents =
        const <ProductBulkUploadDocumentInput>[],
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'upload.xlsx' : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (industryType != null && industryType.trim().isNotEmpty)
        'industry_type': industryType.trim(),
      if (verificationTypes != null && verificationTypes.trim().isNotEmpty)
        'verification_types': verificationTypes.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final List<ProductBulkUploadDocumentInput> cleanDocuments = documents
        .where(
          (ProductBulkUploadDocumentInput doc) =>
              doc.productName.trim().isNotEmpty &&
              doc.label.trim().isNotEmpty &&
              doc.fileBytes.isNotEmpty,
        )
        .toList();
    if (cleanDocuments.isNotEmpty) {
      formData.fields.add(
        MapEntry(
          'doc_product_names',
          cleanDocuments
              .map(
                (ProductBulkUploadDocumentInput doc) => doc.productName.trim(),
              )
              .join(','),
        ),
      );
      formData.fields.add(
        MapEntry(
          'doc_labels',
          cleanDocuments
              .map((ProductBulkUploadDocumentInput doc) => doc.label.trim())
              .join(','),
        ),
      );
      for (final ProductBulkUploadDocumentInput doc in cleanDocuments) {
        final String safeDocName = doc.fileName.trim().isEmpty
            ? 'document.pdf'
            : doc.fileName.trim();
        formData.files.add(
          MapEntry(
            'doc_files',
            MultipartFile.fromBytes(
              doc.fileBytes,
              filename: safeDocName,
              contentType: _mediaTypeForFileName(safeDocName),
            ),
          ),
        );
      }
    }
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

  Future<VerificationBinaryResponse> generateWarrantyTemplate() async {
    return _api.verificationGetBinary(
      '/verification/products/warranty-template',
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

  Future<BulkUploadResponse> createHumanBatch({
    required String batchName,
    String? description,
    required List<Map<String, dynamic>> users,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'batch_name': batchName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'users': users,
    };
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/bulk-upload',
      data: payload,
    );
    return BulkUploadResponse.fromJson(res);
  }

  Future<Map<String, dynamic>> extractHumanOcr({
    required List<Uint8List> files,
    String? fields,
    String? docType,
  }) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      if (fields != null && fields.trim().isNotEmpty) 'fields': fields.trim(),
      if (docType != null && docType.trim().isNotEmpty)
        'doc_type': docType.trim(),
    });
    for (int i = 0; i < files.length; i++) {
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(files[i], filename: 'ocr_$i.jpg'),
        ),
      );
    }
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/ocr/extract',
      formData,
    );
    return res;
  }

  Future<UploadDocumentResponse> uploadHumanDocument({
    required String userId,
    required String documentLabel,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'document.pdf' : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'user_id': userId.trim(),
      'document_label': documentLabel.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/humans/upload-doc',
      formData,
    );
    return UploadDocumentResponse.fromJson(res);
  }

  Future<void> updateBatchUser({
    required String userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? dob,
    String? aadharNumber,
    String? panNumber,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? pincode,
    String? state,
    String? country,
    Map<String, dynamic>? customFields,
    bool markReviewed = true,
  }) async {
    await _api.verificationPatch(
      '/verification/batch-users/${Uri.encodeComponent(userId.trim())}',
      data: <String, dynamic>{
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
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
        if (customFields != null && customFields.isNotEmpty)
          'custom_fields': customFields,
        'mark_reviewed': markReviewed,
      },
    );
  }

  Future<BulkUploadResponse> uploadWarrantyProducts({
    required String batchName,
    String? description,
    List<ProductBulkUploadDocumentInput> documents =
        const <ProductBulkUploadDocumentInput>[],
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty
        ? 'warranty.xlsx'
        : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final List<ProductBulkUploadDocumentInput> cleanDocuments = documents
        .where(
          (ProductBulkUploadDocumentInput doc) =>
              doc.productName.trim().isNotEmpty &&
              doc.label.trim().isNotEmpty &&
              doc.fileBytes.isNotEmpty,
        )
        .toList();
    if (cleanDocuments.isNotEmpty) {
      formData.fields.add(
        MapEntry(
          'doc_product_names',
          cleanDocuments
              .map(
                (ProductBulkUploadDocumentInput doc) => doc.productName.trim(),
              )
              .join(','),
        ),
      );
      formData.fields.add(
        MapEntry(
          'doc_labels',
          cleanDocuments
              .map((ProductBulkUploadDocumentInput doc) => doc.label.trim())
              .join(','),
        ),
      );
      for (final ProductBulkUploadDocumentInput doc in cleanDocuments) {
        final String safeDocName = doc.fileName.trim().isEmpty
            ? 'document.pdf'
            : doc.fileName.trim();
        formData.files.add(
          MapEntry(
            'doc_files',
            MultipartFile.fromBytes(
              doc.fileBytes,
              filename: safeDocName,
              contentType: _mediaTypeForFileName(safeDocName),
            ),
          ),
        );
      }
    }
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/products/warranty-upload',
      formData,
    );
    return BulkUploadResponse.fromJson(res);
  }

  Future<WarrantyBatchStatusResponse> getWarrantyBatchStatus(
    String batchId,
  ) async {
    final Map<String, dynamic> res = await _api.verificationGet(
      '/verification/products/warranty/${Uri.encodeComponent(batchId)}',
    );
    return WarrantyBatchStatusResponse.fromJson(res);
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

  Future<UploadDocumentResponse> uploadProductDocument({
    required String productId,
    required String documentLabel,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'document.pdf' : fileName;
    final String ext = safeName.split('.').last.toLowerCase();
    final MediaType contentType = switch (ext) {
      'png' => MediaType('image', 'png'),
      'jpg' => MediaType('image', 'jpeg'),
      'jpeg' => MediaType('image', 'jpeg'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('application', 'pdf'),
    };
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'document_label': documentLabel.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/products/${Uri.encodeComponent(productId.trim())}/upload-doc',
      formData,
    );
    return UploadDocumentResponse.fromJson(res);
  }

  Future<UploadDocumentResponse> uploadProductDocumentForBatch({
    required String batchId,
    required String productName,
    required String documentLabel,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'document.pdf' : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_id': batchId.trim(),
      'product_name': productName.trim(),
      'document_label': documentLabel.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/products/upload-doc',
      formData,
    );
    return UploadDocumentResponse.fromJson(res);
  }
}
