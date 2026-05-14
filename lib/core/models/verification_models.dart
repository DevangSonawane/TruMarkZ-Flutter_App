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

class VerificationUser {
  const VerificationUser({
    required this.id,
    required this.batchId,
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
      id: (json['id'] ?? '').toString(),
      batchId: (json['batch_id'] ?? '').toString(),
      orgId: (json['org_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      dob: json['dob']?.toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      aadharNumber: json['aadhar_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      addressLine3: json['address_line3']?.toString(),
      pincode: json['pincode']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      verificationStatus: (json['verification_status'] ?? '').toString(),
      verificationReason: json['verification_reason']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
      inviteAccepted: json['invite_accepted'] == true,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      documents: docs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'batch_id': batchId,
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
    return BulkUploadSuccessUser(
      row: int.tryParse((json['row'] ?? '').toString()) ?? 0,
      userId: (json['user_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      inviteLink: (json['invite_link'] ?? '').toString(),
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
    required this.totalUploaded,
    required this.totalSkipped,
    required this.successfulUsers,
    required this.skippedUsers,
    required this.errors,
  });

  final String message;
  final String batchId;
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
