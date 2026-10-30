import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/models/schema_config_models.dart';
import '../../../core/models/sdc_approval_models.dart';
import '../../../core/models/certificate_access_models.dart';
import '../../../core/models/org_permission.dart';
import '../../../core/models/verification_models.dart';
import '../../../core/network/api_client.dart';

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.read(apiClientProvider));
});

final verificationBatchesProvider =
    FutureProvider.autoDispose<List<VerificationBatchSummary>>((ref) async {
      return ref.read(verificationRepositoryProvider).getBatches();
    });

/// Pending + decided partial-SDC approval requests for one batch,
/// newest first. Auto-disposed per batch id; invalidate to refresh after
/// a decide call or on pull-to-refresh.
final sdcApprovalsProvider = FutureProvider.family
    .autoDispose<List<SdcPartialApprovalRequest>, String>((ref, batchId) async {
      return ref
          .read(verificationRepositoryProvider)
          .getSdcApprovals(batchId.trim());
    });

/// Active schema configurations for an organization, keyed by
/// `'<org_id>::<space_type>'`. Invalidate after a stale-selection 400.
final schemaConfigsProvider = FutureProvider.family
    .autoDispose<List<SchemaConfig>, String>((ref, key) async {
      final List<String> parts = key.split('::');
      final String orgId = parts.first.trim();
      final String spaceType = parts.length > 1 ? parts[1].trim() : '';
      if (orgId.isEmpty) return const <SchemaConfig>[];
      return ref
          .read(verificationRepositoryProvider)
          .getSchemaConfigs(
            orgId: orgId,
            spaceType: spaceType.isEmpty ? null : spaceType,
          );
    });

/// Secure Certificate Access state (mode + visitor grants) for one Human
/// batch. Invalidate after a mode change or a revoke.
final certificateAccessProvider = FutureProvider.family
    .autoDispose<CertificateAccessInfo, String>((ref, batchId) async {
      return ref
          .read(verificationRepositoryProvider)
          .getCertificateAccess(batchId.trim());
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

final industryTypesProvider =
    FutureProvider.autoDispose<List<VerificationIndustryType>>((ref) async {
      return ref.read(verificationRepositoryProvider).getIndustryTypes();
    });

final industryTypeNamesForCategoryProvider = FutureProvider.family
    .autoDispose<List<String>, String>((ref, category) async {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final String normalizedCategory = category.trim().toLowerCase();
      final List<VerificationTypeDefinition> verificationTypes = await repo
          .getVerificationTypes(category: normalizedCategory);
      final List<VerificationIndustryType> catalogue = await repo
          .getIndustryTypes();
      final Map<String, String> namesByKey = <String, String>{};
      void addName(String rawName) {
        final String name = rawName.trim();
        if (name.isEmpty) return;
        namesByKey.putIfAbsent(name.toLowerCase(), () => name);
      }

      if (normalizedCategory == 'product') {
        for (final VerificationIndustryType item in catalogue) {
          addName(item.name);
        }
      }
      for (final VerificationTypeDefinition type in verificationTypes) {
        for (final String rawIndustry in type.industryTypes) {
          addName(rawIndustry);
        }
      }
      if (namesByKey.isNotEmpty) {
        return namesByKey.values.toList();
      }

      return catalogue
          .map((VerificationIndustryType item) => item.name.trim())
          .where((String value) => value.isNotEmpty)
          .toList();
    });

class ProductBulkUploadDocumentInput {
  const ProductBulkUploadDocumentInput({
    required this.productName,
    this.skuNo = '',
    required this.label,
    required this.fileBytes,
    required this.fileName,
  });

  final String productName;
  final String skuNo;
  final String label;
  final Uint8List fileBytes;
  final String fileName;
}

class WarrantyBulkUploadDocumentInput {
  const WarrantyBulkUploadDocumentInput({
    required this.serialNo,
    required this.label,
    required this.fileBytes,
    required this.fileName,
  });

  final String serialNo;
  final String label;
  final Uint8List fileBytes;
  final String fileName;
}

class ManualVerifierInput {
  const ManualVerifierInput({
    required this.verificationTypeName,
    required this.verifierEmail,
    this.emailSubject,
    this.emailBody,
    this.userIds = const <String>[],
  });

  final String verificationTypeName;
  final String verifierEmail;
  final String? emailSubject;
  final String? emailBody;
  final List<String> userIds;

  Map<String, dynamic> toJson({required bool includeUserIds}) {
    return <String, dynamic>{
      'verification_type_name': verificationTypeName.trim(),
      'verifier_email': verifierEmail.trim(),
      if (emailSubject != null && emailSubject!.trim().isNotEmpty)
        'email_subject': emailSubject!.trim(),
      if (emailBody != null && emailBody!.trim().isNotEmpty)
        'email_body': emailBody!.trim(),
      if (includeUserIds)
        'user_ids': userIds
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList(),
    };
  }
}

class BulkUploadDocumentInput {
  const BulkUploadDocumentInput({
    required this.fileBytes,
    required this.fileName,
  });

  final Uint8List fileBytes;
  final String fileName;
}

/// Demographic values to apply while the matching OCR files are processed.
/// Indices are deliberately positions in the `files` multipart list, not user
/// ids or labels (those do not exist until the upload finishes).
class BulkUploadDocumentAssignment {
  const BulkUploadDocumentAssignment({
    required this.fileIndices,
    this.gender,
    this.nationality,
    this.email,
  });

  final List<int> fileIndices;
  final String? gender;
  final String? nationality;

  /// An email is always scoped to exactly one uploaded file/user.
  final String? email;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'file_indices': fileIndices,
    if (gender != null && gender!.trim().isNotEmpty) 'gender': gender!.trim(),
    if (nationality != null && nationality!.trim().isNotEmpty)
      'nationality': nationality!.trim(),
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
  };
}

class VerificationRepository {
  VerificationRepository(this._api);

  final ApiClient _api;

  /// Reserved key holding the nested schema record; display-only and never
  /// sent back in edits.
  static const String schemaRecordKey = '__schema_record__';

  static String? _cleanSchemaName(String? schemaName) {
    final String value = schemaName?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// Backend treats empty/"null"/"undefined"/"none" as no template, but a
  /// malformed id is a 400 — only send a real-looking id.
  static String? _cleanTemplateId(String? templateId) {
    final String value = templateId?.trim() ?? '';
    if (value.isEmpty) return null;
    const Set<String> placeholders = <String>{'null', 'undefined', 'none'};
    if (placeholders.contains(value.toLowerCase())) return null;
    return value;
  }

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

  String _schemaConfigsPath(String orgId) =>
      '/auth/organizations/${Uri.encodeComponent(orgId.trim())}/schema-configs';

  Future<List<SchemaConfig>> getSchemaConfigs({
    required String orgId,
    String? spaceType,
    bool activeOnly = true,
  }) async {
    final dynamic res = await _api.verificationGetAny(
      _schemaConfigsPath(orgId),
      queryParameters: <String, String>{
        if (spaceType != null && spaceType.trim().isNotEmpty)
          'space_type': spaceType.trim().toLowerCase(),
        'active_only': activeOnly.toString(),
      },
    );
    final dynamic raw = res is Map ? res['configs'] : res;
    if (raw is! List) return const <SchemaConfig>[];
    return raw
        .whereType<Map>()
        .map((Map e) => SchemaConfig.fromJson(Map<String, dynamic>.from(e)))
        .where((SchemaConfig c) => c.label.isNotEmpty)
        .toList();
  }

  /// [sampleRecord] is the user's pasted JSON record, sent verbatim. Never
  /// pre-fill [inputMap] by guessing meaning; send only explicit choices.
  Future<SchemaConfigSaveResponse> createSchemaConfig({
    required String orgId,
    required String spaceType,
    required String schemaVariant,
    required String schemaId,
    required String spaceId,
    required String label,
    bool isDefault = false,
    Map<String, dynamic>? sampleRecord,
    List<SchemaLocalField>? localFields,
    Map<String, dynamic>? inputMap,
    Map<String, dynamic>? outputMap,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      _schemaConfigsPath(orgId),
      data: _schemaConfigBody(
        spaceType: spaceType,
        schemaVariant: schemaVariant,
        schemaId: schemaId,
        spaceId: spaceId,
        label: label,
        isDefault: isDefault,
        sampleRecord: sampleRecord,
        localFields: localFields,
        inputMap: inputMap,
        outputMap: outputMap,
      ),
    );
    return SchemaConfigSaveResponse.fromJson(res);
  }

  /// Creates a new version. Omitting both [localFields] and a non-empty
  /// [sampleRecord] keeps the previous fields; `localFields: []` clears them.
  Future<SchemaConfigSaveResponse> createSchemaConfigVersion({
    required String orgId,
    required String configId,
    required String spaceType,
    required String schemaVariant,
    required String schemaId,
    required String spaceId,
    required String label,
    bool isDefault = false,
    Map<String, dynamic>? sampleRecord,
    List<SchemaLocalField>? localFields,
    Map<String, dynamic>? inputMap,
    Map<String, dynamic>? outputMap,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '${_schemaConfigsPath(orgId)}/${Uri.encodeComponent(configId.trim())}/versions',
      data: _schemaConfigBody(
        spaceType: spaceType,
        schemaVariant: schemaVariant,
        schemaId: schemaId,
        spaceId: spaceId,
        label: label,
        isDefault: isDefault,
        sampleRecord: sampleRecord,
        localFields: localFields,
        inputMap: inputMap,
        outputMap: outputMap,
      ),
    );
    return SchemaConfigSaveResponse.fromJson(res);
  }

  Future<SchemaConfig> setDefaultSchemaConfig({
    required String orgId,
    required String configId,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '${_schemaConfigsPath(orgId)}/${Uri.encodeComponent(configId.trim())}/set-default',
    );
    return SchemaConfig.fromJson(
      res['config'] is Map ? Map<String, dynamic>.from(res['config']) : res,
    );
  }

  Future<SchemaConfig> deactivateSchemaConfig({
    required String orgId,
    required String configId,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '${_schemaConfigsPath(orgId)}/${Uri.encodeComponent(configId.trim())}/deactivate',
    );
    return SchemaConfig.fromJson(
      res['config'] is Map ? Map<String, dynamic>.from(res['config']) : res,
    );
  }

  Map<String, dynamic> _schemaConfigBody({
    required String spaceType,
    required String schemaVariant,
    required String schemaId,
    required String spaceId,
    required String label,
    required bool isDefault,
    Map<String, dynamic>? sampleRecord,
    List<SchemaLocalField>? localFields,
    Map<String, dynamic>? inputMap,
    Map<String, dynamic>? outputMap,
  }) {
    return <String, dynamic>{
      'space_type': spaceType.trim().toLowerCase(),
      'schema_variant': schemaVariant.trim(),
      'schema_id': schemaId.trim(),
      'space_id': spaceId.trim(),
      'label': label.trim(),
      'is_default': isDefault,
      'sample_record': ?sampleRecord,
      if (localFields != null)
        'local_fields': localFields
            .map((SchemaLocalField f) => f.toJson())
            .toList(),
      'input_map': ?inputMap,
      'output_map': ?outputMap,
    };
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
    final String encodedPublicId = Uri.encodeComponent(publicId.trim());

    debugPrint(
      '[verification-repo] GET /sdc/records/$encodedPublicId instanceKey=${queryParameters['instance_key']}',
    );
    final dynamic res = await _api.verificationGetAny(
      '/sdc/records/$encodedPublicId',
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

  String _certificateAccessPath(String batchId) =>
      '/verification/batches/${Uri.encodeComponent(batchId.trim())}/certificate-access';

  /// Human batches only; another organization's batch returns 404.
  Future<CertificateAccessInfo> getCertificateAccess(String batchId) async {
    final Map<String, dynamic> res = await _api.verificationGet(
      _certificateAccessPath(batchId),
    );
    return CertificateAccessInfo.fromJson(res);
  }

  /// `409` (message shown as-is) when [mode] contradicts the batch's consent
  /// mode; the only accepted change is gating a Permission Required batch
  /// created before Secure Certificate Access shipped.
  Future<CertificateAccessInfo> setCertificateAccessMode({
    required String batchId,
    required String mode,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPut(
      _certificateAccessPath(batchId),
      data: <String, dynamic>{'mode': mode.trim().toLowerCase()},
    );
    return CertificateAccessInfo.fromJson(res);
  }

  Future<CertificateAccessGrant> revokeCertificateAccessGrant({
    required String batchId,
    required String grantId,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '${_certificateAccessPath(batchId)}/grants/${Uri.encodeComponent(grantId.trim())}/revoke',
    );
    return CertificateAccessGrant.fromJson(
      res['grant'] is Map ? Map<String, dynamic>.from(res['grant']) : res,
    );
  }

  /// Fetches a report link with the organization session (§18C). Works for
  /// both public and `holder_approval` batches.
  Future<VerificationBinaryResponse> downloadReport(Uri reportUri) {
    return _api.verificationGetBinaryUrl(reportUri);
  }

  bool isApiReportUrl(Uri uri) => _api.isApiUrl(uri);

  Future<VerificationBinaryResponse> viewRejectedList(String batchId) {
    return _api.verificationGetBinary(
      '/verification/batches/${Uri.encodeComponent(batchId.trim())}/rejected-list/view',
    );
  }

  Future<VerificationBinaryResponse> downloadRejectedList(String batchId) {
    return _api.verificationGetBinary(
      '/verification/batches/${Uri.encodeComponent(batchId.trim())}/rejected-list/download',
    );
  }

  Future<SubmittedVerificationReportsResponse> getSubmittedReports(
    String batchId, {
    bool submittedOnly = true,
  }) async {
    final dynamic res = await _api.verificationGetAny(
      '/verification/batches/${Uri.encodeComponent(batchId.trim())}/submitted-reports',
      queryParameters: submittedOnly
          ? const <String, String>{'submitted_only': 'true'}
          : null,
    );
    return SubmittedVerificationReportsResponse.fromAny(res);
  }

  Future<SingleProductUploadResponse> uploadSingleProduct({
    required String categoryId,
    required String productName,
    Map<String, dynamic>? customFields,
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/single/product',
      data: <String, dynamic>{
        'category_id': categoryId.trim(),
        'product_name': productName.trim(),
        if (customFields != null && customFields.isNotEmpty)
          'custom_fields': customFields,
        'schema_name': ?schema,
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
    String? schemaName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'upload.xlsx' : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final String? schema = _cleanSchemaName(schemaName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      'schema_name': ?schema,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (industryType != null && industryType.trim().isNotEmpty)
        'industry_type': industryType.trim(),
      if (verificationTypes != null && verificationTypes.trim().isNotEmpty)
        'verification_types': verificationTypes.trim(),
      'batch_type': 'product',
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final List<ProductBulkUploadDocumentInput> cleanDocuments = documents
        .where(
          (ProductBulkUploadDocumentInput doc) =>
              doc.skuNo.trim().isNotEmpty &&
              doc.label.trim().isNotEmpty &&
              doc.fileBytes.isNotEmpty,
        )
        .toList();
    if (cleanDocuments.isNotEmpty) {
      formData.fields.add(
        MapEntry(
          'doc_sku_nos',
          cleanDocuments
              .map((ProductBulkUploadDocumentInput doc) => doc.skuNo.trim())
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
    String? categoryId,
    List<String> headers = const <String>[],
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    final List<String> cleanHeaders = headers
        .map((String h) => h.trim())
        .where((String h) => h.isNotEmpty)
        .toList();
    final String headersCsv = cleanHeaders.join(',');
    return _api.verificationPostFormUrlEncodedBinary(
      '/verification/products/template',
      data: <String, dynamic>{
        if (categoryId != null && categoryId.trim().isNotEmpty)
          'category_id': categoryId.trim(),
        // Backend expects a string in x-www-form-urlencoded.
        if (headersCsv.isNotEmpty) 'headers': headersCsv,
        'schema_name': ?schema,
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
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    return _api.verificationPostFormUrlEncodedBinary(
      '/verification/generate-human-template',
      data: <String, dynamic>{
        'headers': headers.trim(),
        if (verificationTypes.trim().isNotEmpty)
          'verification_types': verificationTypes.trim(),
        'schema_name': ?schema,
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
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
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
        'schema_name': ?schema,
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
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    final String? template = _cleanTemplateId(templateId);
    final String? backendVisibility = canonicalCredentialVisibility(
      credentialVisibility,
    );
    if (kDebugMode) {
      debugPrint(
        '[Consent] bulk upload visibility raw=${credentialVisibility ?? ''} '
        'backend=${backendVisibility ?? '(organization default)'}',
      );
    }
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
      if (backendVisibility case final String visibility)
        'credential_visibility': visibility,
      'template_id': ?template,
      'schema_name': ?schema,
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

  Future<BulkUploadResponse> bulkUploadDocuments({
    required String batchName,
    String? description,
    String? industryType,
    String? verificationTypes,
    String? credentialVisibility,
    String? docType,
    String? fields,
    List<BulkUploadDocumentAssignment> assignments =
        const <BulkUploadDocumentAssignment>[],
    required List<BulkUploadDocumentInput> files,
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    final String? backendVisibility = canonicalCredentialVisibility(
      credentialVisibility,
    );
    if (kDebugMode) {
      debugPrint(
        '[Consent] document upload visibility raw=${credentialVisibility ?? ''} '
        'backend=${backendVisibility ?? '(organization default)'}',
      );
    }
    final List<BulkUploadDocumentInput> cleanFiles = files
        .where(
          (BulkUploadDocumentInput file) =>
              file.fileBytes.isNotEmpty && file.fileName.trim().isNotEmpty,
        )
        .toList();
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (industryType != null && industryType.trim().isNotEmpty)
        'industry_type': industryType.trim(),
      if (verificationTypes != null && verificationTypes.trim().isNotEmpty)
        'verification_types': verificationTypes.trim(),
      if (backendVisibility case final String visibility)
        'credential_visibility': visibility,
      if (docType != null && docType.trim().isNotEmpty)
        'doc_type': docType.trim(),
      if (fields != null && fields.trim().isNotEmpty) 'fields': fields.trim(),
      'schema_name': ?schema,
      if (assignments.isNotEmpty)
        'assignments': jsonEncode(
          assignments
              .map((BulkUploadDocumentAssignment item) => item.toJson())
              .toList(),
        ),
    });
    for (final BulkUploadDocumentInput file in cleanFiles) {
      final String safeName = file.fileName.trim().isEmpty
          ? 'document.jpg'
          : file.fileName.trim();
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.fileBytes,
            filename: safeName,
            contentType: _mediaTypeForFileName(safeName),
          ),
        ),
      );
    }
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/bulk-upload/documents',
      formData,
    );
    return BulkUploadResponse.fromJson(res);
  }

  Future<BulkUploadResponse> createHumanBatch({
    required String batchName,
    String? description,
    required List<Map<String, dynamic>> users,
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    final Map<String, dynamic> payload = <String, dynamic>{
      'batch_name': batchName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'schema_name': ?schema,
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
    String? gender,
    String? nationality,
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
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
        if (nationality != null && nationality.trim().isNotEmpty)
          'nationality': nationality.trim(),
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
        if (_editableCustomFields(customFields)
            case final Map<String, dynamic> fields)
          'custom_fields': fields,
        'mark_reviewed': markReviewed,
      },
    );
  }

  /// Drops the reserved nested schema record so it is never sent back.
  static Map<String, dynamic>? _editableCustomFields(
    Map<String, dynamic>? customFields,
  ) {
    if (customFields == null || customFields.isEmpty) return null;
    final Map<String, dynamic> cleaned = Map<String, dynamic>.from(customFields)
      ..remove(schemaRecordKey);
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<BulkUploadResponse> uploadWarrantyProducts({
    required String batchName,
    String? description,
    List<String> reservedSerialNos = const <String>[],
    List<WarrantyBulkUploadDocumentInput> documents =
        const <WarrantyBulkUploadDocumentInput>[],
    required Uint8List fileBytes,
    required String fileName,
    String? schemaName,
  }) async {
    final String? schema = _cleanSchemaName(schemaName);
    final String safeName = fileName.trim().isEmpty
        ? 'warranty.xlsx'
        : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_name': batchName.trim(),
      'batch_type': 'warranty',
      'schema_name': ?schema,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final List<String> cleanReservedSerialNos = reservedSerialNos
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
    if (cleanReservedSerialNos.isNotEmpty) {
      formData.fields.add(
        MapEntry('reserved_serial_nos', cleanReservedSerialNos.join(',')),
      );
      formData.fields.add(
        const MapEntry<String, String>('use_reserved_serials', 'true'),
      );
    }

    final List<WarrantyBulkUploadDocumentInput> cleanDocuments = documents
        .where(
          (WarrantyBulkUploadDocumentInput doc) =>
              doc.serialNo.trim().isNotEmpty &&
              doc.label.trim().isNotEmpty &&
              doc.fileBytes.isNotEmpty,
        )
        .toList();
    if (cleanDocuments.isNotEmpty) {
      formData.fields.add(
        MapEntry(
          'doc_serial_nos',
          cleanDocuments
              .map((WarrantyBulkUploadDocumentInput doc) => doc.serialNo.trim())
              .join(','),
        ),
      );
      formData.fields.add(
        MapEntry(
          'doc_labels',
          cleanDocuments
              .map((WarrantyBulkUploadDocumentInput doc) => doc.label.trim())
              .join(','),
        ),
      );
      for (final WarrantyBulkUploadDocumentInput doc in cleanDocuments) {
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

  Future<WarrantySerialReservationResponse> reserveWarrantySerials({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty
        ? 'warranty.xlsx'
        : fileName;
    final MediaType contentType = _mediaTypeForFileName(safeName);
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: contentType,
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/products/warranty-reserve-serials',
      formData,
    );
    return WarrantySerialReservationResponse.fromJson(res);
  }

  Future<WarrantyBatchStatusResponse> getWarrantyBatchStatus(
    String batchId,
  ) async {
    final Map<String, dynamic> res = await _api.verificationGet(
      '/verification/products/warranty/${Uri.encodeComponent(batchId)}',
    );
    return WarrantyBatchStatusResponse.fromJson(res);
  }

  Future<WarrantyBatchStatusResponse> getSdcBatchStatus(String batchId) async {
    final String encodedBatchId = Uri.encodeComponent(batchId.trim());
    final Map<String, dynamic> res = await _api.verificationGet(
      '/sdc/batches/$encodedBatchId/status',
    );
    return WarrantyBatchStatusResponse.fromJson(res);
  }

  Future<SdcGenerateResponse> generateSdcBatch({
    required String batchId,
    bool publish = false,
    bool active = false,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/sdc/batches/${Uri.encodeComponent(batchId.trim())}/generate',
      data: <String, dynamic>{'publish': publish, 'active': active},
    );
    return SdcGenerateResponse.fromJson(res);
  }

  Future<Map<String, dynamic>> sendManualBulkVerification({
    required String batchId,
    required List<ManualVerifierInput> verifiers,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/manual/send-bulk',
      skipAuth: true,
      data: <String, dynamic>{
        'batch_id': batchId.trim(),
        'verifiers': verifiers
            .map(
              (ManualVerifierInput verifier) =>
                  verifier.toJson(includeUserIds: false),
            )
            .toList(),
      },
    );
    return res;
  }

  Future<Map<String, dynamic>> smartSendManualVerification({
    required String batchId,
    required List<ManualVerifierInput> verifiers,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/manual/smart-send',
      skipAuth: true,
      data: <String, dynamic>{
        'batch_id': batchId.trim(),
        'verifiers': verifiers
            .map(
              (ManualVerifierInput verifier) =>
                  verifier.toJson(includeUserIds: true),
            )
            .toList(),
      },
    );
    return res;
  }

  Future<Map<String, dynamic>> updateManualRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final Map<String, dynamic> res = await _api.verificationPatch(
      '/verification/manual/requests/${Uri.encodeComponent(requestId.trim())}/status',
      data: <String, dynamic>{'status': status.trim()},
    );
    return res;
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

  /// Stage 2 of the OCR Human workflow (trumarkz_ocr.md §3.2):
  /// single photo for one BatchUser created by bulk-upload/documents.
  Future<OcrPhotoUploadResponse> uploadOcrPhoto({
    required String batchUserId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final String safeName = fileName.trim().isEmpty ? 'photo.jpg' : fileName;
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batch_user_id': batchUserId.trim(),
      'photo': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
        contentType: _mediaTypeForFileName(safeName),
      ),
    });
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/upload/ocr-photo',
      formData,
    );
    return OcrPhotoUploadResponse.fromJson(res);
  }

  /// Stage 2 bulk (trumarkz_ocr.md §3.3): positional
  /// `batch_user_ids[i] ↔ photos[i]`. Both lists must be same length —
  /// callers must preserve `successful_users[]` order and exclude skips.
  Future<BulkOcrPhotoUploadResponse> bulkUploadOcrPhotos({
    required List<String> batchUserIds,
    required List<BulkUploadDocumentInput> photos,
  }) async {
    assert(
      batchUserIds.length == photos.length,
      'batch_user_ids and photos must contain the same number of items',
    );
    final FormData formData = FormData.fromMap(<String, dynamic>{});
    for (final String id in batchUserIds) {
      formData.fields.add(MapEntry('batch_user_ids', id.trim()));
    }
    for (final BulkUploadDocumentInput photo in photos) {
      final String safeName = photo.fileName.trim().isEmpty
          ? 'photo.jpg'
          : photo.fileName.trim();
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(
            photo.fileBytes,
            filename: safeName,
            contentType: _mediaTypeForFileName(safeName),
          ),
        ),
      );
    }
    final Map<String, dynamic> res = await _api.verificationPostMultipart(
      '/verification/bulk-upload/ocr-photos',
      formData,
    );
    return BulkOcrPhotoUploadResponse.fromJson(res);
  }

  /// Partial-SDC approval (org side only, sdc_partial_approval_flutter.md).
  ///
  /// GET /sdc/batches/{batch_id}/approvals — list, newest first, every
  /// request ever made for that batch (not just pending). Callers filter
  /// client-side for `status == pending` for badge counts.
  Future<List<SdcPartialApprovalRequest>> getSdcApprovals(
    String batchId,
  ) async {
    final String encoded = Uri.encodeComponent(batchId.trim());
    final dynamic res = await _api.verificationGetAny(
      '/sdc/batches/$encoded/approvals',
    );
    final List<dynamic> rawItems;
    if (res is List) {
      rawItems = res;
    } else if (res is Map) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(res);
      final dynamic data =
          json['data'] ??
          json['approvals'] ??
          json['requests'] ??
          json['items'];
      rawItems = data is List ? data : const <dynamic>[];
    } else {
      rawItems = const <dynamic>[];
    }
    final List<SdcPartialApprovalRequest> items = rawItems
        .whereType<Map>()
        .map(
          (Map e) =>
              SdcPartialApprovalRequest.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((SdcPartialApprovalRequest r) => r.id.isNotEmpty)
        .toList();
    // Response is newest-first from the server; keep that order.
    return items;
  }

  /// POST /sdc/approvals/{request_id}/decide
  /// [decision] must be exactly 'approved' or 'rejected' (lowercase).
  /// Returns the updated request. Throws [ApiException] with:
  /// 404 (not found / wrong org), 409 (already decided), 400 (bad decision).
  Future<SdcPartialApprovalRequest> decideSdcApproval({
    required String requestId,
    required String decision,
    String? reason,
  }) async {
    final String normalized = decision.trim().toLowerCase();
    final String encoded = Uri.encodeComponent(requestId.trim());
    final Map<String, dynamic> res = await _api.verificationPost(
      '/sdc/approvals/$encoded/decide',
      data: <String, dynamic>{
        'decision': normalized,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return SdcPartialApprovalRequest.fromJson(res);
  }
}
