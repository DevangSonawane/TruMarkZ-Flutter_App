import 'dart:convert';

class VerificationDocument {
  const VerificationDocument({
    required this.id,
    required this.documentLabel,
    required this.documentUrl,
    required this.version,
    required this.verificationStatus,
    required this.verificationReason,
    required this.verifiedAt,
    required this.uploadedAt,
  });

  final String id;
  final String documentLabel;
  final String documentUrl;
  final int version;
  final String verificationStatus; // 'pending' | 'verified' | 'failed'
  final String? verificationReason;
  final String? verifiedAt;
  final String uploadedAt;

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: (json['id'] ?? '').toString(),
      documentLabel: (json['document_label'] ?? '').toString(),
      documentUrl: (json['document_url'] ?? '').toString(),
      version: int.tryParse((json['version'] ?? '').toString()) ?? 0,
      verificationStatus: (json['verification_status'] ?? '').toString(),
      verificationReason: json['verification_reason']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      uploadedAt: (json['uploaded_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'document_label': documentLabel,
    'document_url': documentUrl,
    'version': version,
    'verification_status': verificationStatus,
    'verification_reason': verificationReason,
    'verified_at': verifiedAt,
    'uploaded_at': uploadedAt,
  };
}

class VerificationTypeDefinition {
  const VerificationTypeDefinition({
    required this.id,
    required this.name,
    required this.label,
    required this.category,
    required this.industryTypes,
    required this.emailAddress,
    required this.apiLink,
    required this.price,
    required this.timeline,
  });

  final String id;
  final String name;
  final String label;
  final String category;
  final List<String> industryTypes;
  final String? emailAddress;
  final String? apiLink;
  final int? price;
  final String? timeline;

  factory VerificationTypeDefinition.fromJson(Map<String, dynamic> json) {
    final Object? rawPrice = json['price'];
    return VerificationTypeDefinition(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      industryTypes: _readStringList(json['industry_type']),
      emailAddress: json['email_address']?.toString(),
      apiLink: json['api_link']?.toString(),
      price: rawPrice is num
          ? rawPrice.toInt()
          : int.tryParse(rawPrice?.toString() ?? ''),
      timeline: json['timeline']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'label': label,
    'category': category,
    'email_address': emailAddress,
    'api_link': apiLink,
    'price': price,
    'timeline': timeline,
  };
}

List<String> _readStringList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
  }
  if (raw is String) {
    final String value = raw.trim();
    if (value.isEmpty) return const <String>[];
    if (value.startsWith('[')) {
      try {
        final dynamic decoded = jsonDecode(value);
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
    return value
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }
  return const <String>[];
}

class VerificationUser {
  const VerificationUser({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.orgId,
    required this.fullName,
    required this.dob,
    required this.phoneNumber,
    required this.email,
    required this.aadharNumber,
    required this.panNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.addressLine3,
    required this.pincode,
    required this.state,
    required this.country,
    required this.verificationStatus,
    required this.verificationReason,
    required this.verifiedAt,
    required this.photoUrl,
    required this.storagePath,
    required this.inviteAccepted,
    required this.createdAt,
    required this.updatedAt,
    required this.documents,
  });

  final String id;
  final String batchId;
  final String batchName;
  final String orgId;
  final String fullName;
  final String? dob;
  final String phoneNumber;
  final String email;
  final String? aadharNumber;
  final String? panNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? pincode;
  final String? state;
  final String? country;
  final String
  verificationStatus; // 'pending_verification' | 'verified' | 'failed'
  final String? verificationReason;
  final String? verifiedAt;
  final String? photoUrl;
  final String storagePath;
  final bool inviteAccepted;
  final String createdAt;
  final String updatedAt;
  final List<VerificationDocument> documents;

  factory VerificationUser.fromJson(Map<String, dynamic> json) {
    String readString(dynamic v) => (v ?? '').toString();

    String readBatchName(Map<String, dynamic> json) {
      // Backend payloads vary; accept common keys and nested objects.
      final String direct = readString(json['batch_name']).trim().isNotEmpty
          ? readString(json['batch_name'])
          : (readString(json['batchName']).trim().isNotEmpty
                ? readString(json['batchName'])
                : (readString(json['batch_title']).trim().isNotEmpty
                      ? readString(json['batch_title'])
                      : (readString(json['batchTitle']).trim().isNotEmpty
                            ? readString(json['batchTitle'])
                            : '')));
      if (direct.trim().isNotEmpty) return direct.trim();

      final dynamic batchObj = json['batch'];
      if (batchObj is String && batchObj.trim().isNotEmpty) {
        return batchObj.trim();
      }
      if (batchObj is Map) {
        final Map<String, dynamic> batch = Map<String, dynamic>.from(batchObj);
        final String nested = readString(batch['name']).trim().isNotEmpty
            ? readString(batch['name'])
            : (readString(batch['batch_name']).trim().isNotEmpty
                  ? readString(batch['batch_name'])
                  : (readString(batch['title']).trim().isNotEmpty
                        ? readString(batch['title'])
                        : ''));
        if (nested.trim().isNotEmpty) return nested.trim();
      }
      return '';
    }

    final dynamic docsRaw = json['documents'];
    final List<VerificationDocument> docs = docsRaw is List
        ? docsRaw
              .whereType<Map>()
              .map(
                (Map e) =>
                    VerificationDocument.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <VerificationDocument>[];

    return VerificationUser(
      id: readString(json['id']),
      batchId: readString(json['batch_id']),
      batchName: readBatchName(json),
      orgId: readString(json['org_id']),
      fullName: readString(json['full_name']),
      dob: json['dob']?.toString(),
      phoneNumber: readString(json['phone_number']),
      email: readString(json['email']),
      aadharNumber: json['aadhar_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      addressLine3: json['address_line3']?.toString(),
      pincode: json['pincode']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      verificationStatus: readString(json['verification_status']),
      verificationReason: json['verification_reason']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      storagePath: readString(json['storage_path']),
      inviteAccepted: json['invite_accepted'] == true,
      createdAt: readString(json['created_at']),
      updatedAt: readString(json['updated_at']),
      documents: docs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'batch_id': batchId,
    'batch_name': batchName,
    'org_id': orgId,
    'full_name': fullName,
    'dob': dob,
    'phone_number': phoneNumber,
    'email': email,
    'aadhar_number': aadharNumber,
    'pan_number': panNumber,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'address_line3': addressLine3,
    'pincode': pincode,
    'state': state,
    'country': country,
    'verification_status': verificationStatus,
    'verification_reason': verificationReason,
    'verified_at': verifiedAt,
    'photo_url': photoUrl,
    'storage_path': storagePath,
    'invite_accepted': inviteAccepted,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'documents': documents.map((VerificationDocument d) => d.toJson()).toList(),
  };
}

class VerificationListResponse {
  const VerificationListResponse({
    required this.total,
    required this.pending,
    required this.verified,
    required this.failed,
    required this.users,
  });

  final int total;
  final int pending;
  final int verified;
  final int failed;
  final List<VerificationUser> users;

  factory VerificationListResponse.fromJson(Map<String, dynamic> json) {
    final dynamic usersRaw = json['users'];
    final List<VerificationUser> users = usersRaw is List
        ? usersRaw
              .whereType<Map>()
              .map(
                (Map e) =>
                    VerificationUser.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <VerificationUser>[];
    return VerificationListResponse(
      total: int.tryParse((json['total'] ?? '').toString()) ?? users.length,
      pending: int.tryParse((json['pending'] ?? '').toString()) ?? 0,
      verified: int.tryParse((json['verified'] ?? '').toString()) ?? 0,
      failed: int.tryParse((json['failed'] ?? '').toString()) ?? 0,
      users: users,
    );
  }
}

class VerificationBatchSummary {
  const VerificationBatchSummary({
    required this.batchId,
    required this.batchName,
    required this.totalUsers,
    required this.verified,
    required this.failed,
    required this.createdAt,
    required this.excelStoragePath,
    required this.reportStoragePaths,
  });

  final String batchId;
  final String batchName;
  final int totalUsers;
  final int verified;
  final int failed;
  final String createdAt;
  final String excelStoragePath;
  final List<String> reportStoragePaths;

  int get pending => (totalUsers - verified - failed).clamp(0, totalUsers);

  factory VerificationBatchSummary.fromJson(Map<String, dynamic> json) {
    final dynamic reportsRaw = json['report_storage_paths'];
    final List<String> reports = reportsRaw is List
        ? reportsRaw
              .map((dynamic e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList()
        : <String>[];

    return VerificationBatchSummary(
      batchId: (json['batch_id'] ?? json['batchId'] ?? '').toString().trim(),
      batchName: (json['batch_name'] ?? json['batchName'] ?? '').toString().trim(),
      totalUsers: int.tryParse((json['total_users'] ?? json['totalUsers'] ?? '').toString()) ?? 0,
      verified: int.tryParse((json['verified'] ?? '').toString()) ?? 0,
      failed: int.tryParse((json['failed'] ?? '').toString()) ?? 0,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString().trim(),
      excelStoragePath: (json['excel_storage_path'] ?? json['excelStoragePath'] ?? '').toString().trim(),
      reportStoragePaths: reports,
    );
  }
}

class VerificationBatchDetailResponse {
  const VerificationBatchDetailResponse({
    required this.batchId,
    required this.batchName,
    required this.description,
    required this.industryTypes,
    required this.verificationTypes,
    required this.credentialVisibility,
    required this.totalUsers,
    required this.verificationProgress,
    required this.users,
    required this.excelStoragePath,
    required this.reportStoragePaths,
  });

  final String batchId;
  final String batchName;
  final String description;
  final List<String> industryTypes;
  final List<String> verificationTypes;
  final String credentialVisibility;
  final int totalUsers;
  final Map<String, dynamic> verificationProgress;
  final List<VerificationUser> users;
  final String excelStoragePath;
  final List<String> reportStoragePaths;

  factory VerificationBatchDetailResponse.fromJson(Map<String, dynamic> json) {
    final dynamic reportsRaw = json['report_storage_paths'];
    final List<String> reports = reportsRaw is List
        ? reportsRaw
              .map((dynamic e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList()
        : <String>[];
    final dynamic industryRaw = json['industry_type'];
    final List<String> industries = industryRaw is List
        ? industryRaw
              .map((dynamic e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList()
        : <String>[];
    final dynamic typesRaw = json['verification_types'];
    final List<String> types = typesRaw is List
        ? typesRaw
              .map((dynamic e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList()
        : <String>[];
    final dynamic usersRaw = json['users'];
    final List<VerificationUser> users = usersRaw is List
        ? usersRaw
              .whereType<Map>()
              .map(
                (Map e) =>
                    VerificationUser.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <VerificationUser>[];

    return VerificationBatchDetailResponse(
      batchId: (json['batch_id'] ?? json['batchId'] ?? '').toString().trim(),
      batchName: (json['batch_name'] ?? json['batchName'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      industryTypes: industries,
      verificationTypes: types,
      credentialVisibility: (json['credential_visibility'] ?? '').toString().trim(),
      totalUsers: int.tryParse((json['total_users'] ?? json['totalUsers'] ?? '').toString()) ?? users.length,
      verificationProgress: json['verification_progress'] is Map
          ? Map<String, dynamic>.from(json['verification_progress'] as Map)
          : <String, dynamic>{},
      users: users,
      excelStoragePath: (json['excel_storage_path'] ?? json['excelStoragePath'] ?? '').toString().trim(),
      reportStoragePaths: reports,
    );
  }
}

class VerificationCategory {
  const VerificationCategory({
    required this.id,
    required this.categoryName,
    required this.warrantySupport,
    required this.description,
  });

  final String id;
  final String categoryName;
  final String warrantySupport;
  final String description;

  bool get supportsWarranty {
    final String v = warrantySupport.trim().toLowerCase();
    if (v.isEmpty) return false;
    // Treat only explicit negatives as false; backend often sends
    // strings like "enabled"/"available"/"supported".
    const Set<String> falsey = <String>{
      'false',
      '0',
      'no',
      'none',
      'unsupported',
      'not_supported',
      'disabled',
      'disable',
      'na',
      'n/a',
    };
    return !falsey.contains(v);
  }

  factory VerificationCategory.fromJson(Map<String, dynamic> json) {
    final dynamic rawWarranty = json['warranty_support'];
    final String warranty = rawWarranty is bool
        ? (rawWarranty ? 'true' : 'false')
        : (rawWarranty ?? '').toString();
    return VerificationCategory(
      id: (json['id'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      warrantySupport: warranty,
      description: (json['description'] ?? '').toString(),
    );
  }
}

class VerificationIndustryType {
  const VerificationIndustryType({
    required this.name,
    required this.warrantySupport,
  });

  final String name;
  final String warrantySupport;

  bool get supportsWarranty {
    final String v = warrantySupport.trim().toLowerCase();
    if (v.isEmpty) return false;
    return v != 'disabled' &&
        v != 'false' &&
        v != '0' &&
        v != 'no' &&
        v != 'none' &&
        v != 'unsupported' &&
        v != 'not_supported';
  }

  factory VerificationIndustryType.fromJson(Map<String, dynamic> json) {
    final dynamic rawWarranty = json['warranty_support'];
    final String warranty = rawWarranty is bool
        ? (rawWarranty ? 'true' : 'false')
        : (rawWarranty ?? '').toString();
    return VerificationIndustryType(
      name: (json['name'] ?? '').toString(),
      warrantySupport: warranty,
    );
  }
}

class WarrantyBatchProduct {
  const WarrantyBatchProduct({
    required this.id,
    required this.productName,
    required this.category,
    required this.serialNumber,
    required this.purchaseDate,
    required this.warrantyStartDate,
    required this.warrantyEndDate,
    required this.warrantyStatus,
    required this.reason,
  });

  final String id;
  final String productName;
  final String category;
  final String serialNumber;
  final String purchaseDate;
  final String warrantyStartDate;
  final String warrantyEndDate;
  final String warrantyStatus;
  final String? reason;

  factory WarrantyBatchProduct.fromJson(Map<String, dynamic> json) {
    String readString(dynamic v) => (v ?? '').toString().trim();

    return WarrantyBatchProduct(
      id: readString(json['id']),
      productName: readString(
        json['product_name'] ?? json['productName'] ?? json['name'],
      ),
      category: readString(json['category'] ?? json['category_name']),
      serialNumber: readString(
        json['serial_number'] ?? json['serialNumber'] ?? json['serial'],
      ),
      purchaseDate: readString(
        json['purchase_date'] ?? json['purchaseDate'],
      ),
      warrantyStartDate: readString(
        json['warranty_start_date'] ?? json['warrantyStartDate'],
      ),
      warrantyEndDate: readString(
        json['warranty_end_date'] ?? json['warrantyEndDate'],
      ),
      warrantyStatus: readString(
        json['warranty_status'] ?? json['status'] ?? json['approval_status'],
      ),
      reason: json['reason']?.toString(),
    );
  }
}

class WarrantyBatchStatusResponse {
  const WarrantyBatchStatusResponse({
    required this.batchId,
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.products,
  });

  final String batchId;
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final List<WarrantyBatchProduct> products;

  factory WarrantyBatchStatusResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};
    final dynamic productsRaw =
        json['products'] ?? json['warranty_products'] ?? json['items'];
    final List<WarrantyBatchProduct> products = productsRaw is List
        ? productsRaw
              .whereType<Map>()
              .map(
                (Map e) => WarrantyBatchProduct.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : const <WarrantyBatchProduct>[];

    int readCount(List<String> keys, int fallback) {
      for (final String key in keys) {
        final dynamic raw = json[key] ?? summary[key];
        final int? parsed = int.tryParse((raw ?? '').toString());
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    return WarrantyBatchStatusResponse(
      batchId: (json['batch_id'] ?? json['batchId'] ?? '').toString().trim(),
      total: readCount(<String>['total', 'count'], products.length),
      pending: readCount(<String>['pending', 'pending_count'], 0),
      approved: readCount(<String>['approved', 'approved_count'], 0),
      rejected: readCount(<String>['rejected', 'rejected_count'], 0),
      products: products,
    );
  }
}

class VerificationTemplate {
  const VerificationTemplate({
    required this.id,
    required this.templateName,
    required this.verificationTypes,
    required this.jsonData,
    required this.htmlCode,
    required this.version,
  });

  final String id;
  final String templateName;
  final List<String> verificationTypes;
  final Map<String, dynamic> jsonData;
  final String htmlCode;
  final int version;

  factory VerificationTemplate.fromJson(Map<String, dynamic> json) {
    final dynamic typesRaw = json['verification_types'];
    final List<String> types = typesRaw is List
        ? typesRaw
              .map((dynamic e) => e?.toString().trim() ?? '')
              .where((String e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final dynamic dataRaw = json['json_data'];
    final Map<String, dynamic> data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : <String, dynamic>{};

    return VerificationTemplate(
      id: (json['id'] ?? '').toString(),
      templateName: (json['template_name'] ?? '').toString(),
      verificationTypes: types,
      jsonData: data,
      htmlCode: (json['html_code'] ?? '').toString(),
      version: int.tryParse((json['version'] ?? '').toString()) ?? 0,
    );
  }
}

class BulkUploadSuccessUser {
  const BulkUploadSuccessUser({
    required this.row,
    required this.userId,
    required this.email,
    required this.phoneNumber,
    required this.fullName,
    required this.token,
    required this.inviteLink,
  });

  final int row;
  final String userId;
  final String email;
  final String phoneNumber;
  final String fullName;
  final String token;
  final String inviteLink;

  factory BulkUploadSuccessUser.fromJson(Map<String, dynamic> json) {
    final String productName =
        (json['product_name'] ?? json['productName'] ?? json['name'] ?? '')
            .toString();
    return BulkUploadSuccessUser(
      row: int.tryParse((json['row'] ?? '').toString()) ?? 0,
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      email: (json['email'] ?? json['contact_email'] ?? '').toString(),
      phoneNumber:
          (json['phone_number'] ?? json['phone'] ?? json['contact_phone'] ?? '')
              .toString(),
      fullName: (json['full_name'] ?? productName).toString(),
      token: (json['token'] ?? json['invite_token'] ?? '').toString(),
      inviteLink: (json['invite_link'] ?? json['link'] ?? '').toString(),
    );
  }
}

class BulkUploadSkippedUser {
  const BulkUploadSkippedUser({required this.row, required this.reason});

  final int row;
  final String reason;

  factory BulkUploadSkippedUser.fromJson(Map<String, dynamic> json) {
    return BulkUploadSkippedUser(
      row: int.tryParse((json['row'] ?? '').toString()) ?? 0,
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class BulkUploadErrorRow {
  const BulkUploadErrorRow({
    required this.row,
    required this.field,
    required this.error,
  });

  final int row;
  final String field;
  final String error;

  factory BulkUploadErrorRow.fromJson(Map<String, dynamic> json) {
    return BulkUploadErrorRow(
      row: int.tryParse((json['row'] ?? '').toString()) ?? 0,
      field: (json['field'] ?? '').toString(),
      error: (json['error'] ?? '').toString(),
    );
  }
}

class BulkUploadResponse {
  const BulkUploadResponse({
    required this.message,
    required this.batchId,
    required this.entityType,
    required this.totalUploaded,
    required this.totalSkipped,
    required this.successfulUsers,
    required this.skippedUsers,
    required this.errors,
  });

  final String message;
  final String batchId;
  final String entityType;
  final int totalUploaded;
  final int totalSkipped;
  final List<BulkUploadSuccessUser> successfulUsers;
  final List<BulkUploadSkippedUser> skippedUsers;
  final List<BulkUploadErrorRow> errors;

  factory BulkUploadResponse.fromJson(Map<String, dynamic> json) {
    final dynamic successRaw = json['successful_users'];
    final dynamic skippedRaw = json['skipped_users'];
    final dynamic errorsRaw = json['errors'];

    return BulkUploadResponse(
      message: (json['message'] ?? '').toString(),
      batchId: (json['batch_id'] ?? '').toString(),
      entityType: (json['entity_type'] ?? json['entityType'] ?? '').toString(),
      totalUploaded:
          int.tryParse((json['total_uploaded'] ?? '').toString()) ?? 0,
      totalSkipped: int.tryParse((json['total_skipped'] ?? '').toString()) ?? 0,
      successfulUsers: successRaw is List
          ? successRaw
                .whereType<Map>()
                .map(
                  (Map e) => BulkUploadSuccessUser.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <BulkUploadSuccessUser>[],
      skippedUsers: skippedRaw is List
          ? skippedRaw
                .whereType<Map>()
                .map(
                  (Map e) => BulkUploadSkippedUser.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <BulkUploadSkippedUser>[],
      errors: errorsRaw is List
          ? errorsRaw
                .whereType<Map>()
                .map(
                  (Map e) =>
                      BulkUploadErrorRow.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <BulkUploadErrorRow>[],
    );
  }
}

class SingleHumanUploadResponse {
  const SingleHumanUploadResponse({
    required this.message,
    required this.entityId,
    required this.entityType,
    required this.inviteToken,
    required this.inviteLink,
  });

  final String message;
  final String entityId;
  final String entityType;
  final String inviteToken;
  final String inviteLink;

  factory SingleHumanUploadResponse.fromJson(Map<String, dynamic> json) {
    return SingleHumanUploadResponse(
      message: (json['message'] ?? '').toString(),
      entityId: (json['entity_id'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      inviteToken: (json['invite_token'] ?? '').toString(),
      inviteLink: (json['invite_link'] ?? '').toString(),
    );
  }
}

class SingleProductUploadResponse {
  const SingleProductUploadResponse({
    required this.message,
    required this.entityId,
    required this.entityType,
    required this.inviteToken,
    required this.inviteLink,
  });

  final String message;
  final String entityId;
  final String entityType;
  final String inviteToken;
  final String inviteLink;

  factory SingleProductUploadResponse.fromJson(Map<String, dynamic> json) {
    return SingleProductUploadResponse(
      message: (json['message'] ?? '').toString(),
      entityId: (json['entity_id'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      inviteToken: (json['invite_token'] ?? '').toString(),
      inviteLink: (json['invite_link'] ?? '').toString(),
    );
  }
}

class GenerateCertificateResponse {
  const GenerateCertificateResponse({
    required this.message,
    required this.pdfUrl,
    required this.qrCodeData,
  });

  final String message;
  final String pdfUrl;
  final String qrCodeData;

  factory GenerateCertificateResponse.fromJson(Map<String, dynamic> json) {
    return GenerateCertificateResponse(
      message: (json['message'] ?? '').toString(),
      pdfUrl: (json['pdf_url'] ?? '').toString(),
      qrCodeData: (json['qr_code_data'] ?? '').toString(),
    );
  }
}

class UploadPhotoResponse {
  const UploadPhotoResponse({required this.message, required this.photoUrl});

  final String message;
  final String photoUrl;

  factory UploadPhotoResponse.fromJson(Map<String, dynamic> json) {
    return UploadPhotoResponse(
      message: (json['message'] ?? '').toString(),
      photoUrl: (json['photo_url'] ?? '').toString(),
    );
  }
}

class UploadDocumentResponse {
  const UploadDocumentResponse({
    required this.message,
    required this.documentId,
    required this.documentUrl,
    required this.version,
  });

  final String message;
  final String documentId;
  final String documentUrl;
  final int version;

  factory UploadDocumentResponse.fromJson(Map<String, dynamic> json) {
    return UploadDocumentResponse(
      message: (json['message'] ?? '').toString(),
      documentId: (json['document_id'] ?? '').toString(),
      documentUrl: (json['document_url'] ?? '').toString(),
      version: int.tryParse((json['version'] ?? '').toString()) ?? 0,
    );
  }
}
