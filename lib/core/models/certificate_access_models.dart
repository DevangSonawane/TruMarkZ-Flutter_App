/// Human Secure Certificate Access
/// (`/verification/batches/{batch_id}/certificate-access`).
class CertificateAccessInfo {
  const CertificateAccessInfo({
    required this.batchId,
    required this.mode,
    required this.grants,
  });

  final String batchId;

  /// `public` | `holder_approval`.
  final String mode;
  final List<CertificateAccessGrant> grants;

  bool get isHolderApproval => mode == 'holder_approval';

  factory CertificateAccessInfo.fromJson(Map<String, dynamic> json) {
    final dynamic grantsRaw = json['grants'];
    return CertificateAccessInfo(
      batchId: (json['batch_id'] ?? '').toString().trim(),
      mode: (json['mode'] ?? '').toString().trim().toLowerCase(),
      grants: grantsRaw is List
          ? grantsRaw
                .whereType<Map>()
                .map(
                  (Map e) => CertificateAccessGrant.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <CertificateAccessGrant>[],
    );
  }
}

/// A visitor's request to open a holder's reports.
class CertificateAccessGrant {
  const CertificateAccessGrant({
    required this.id,
    required this.batchUserId,
    required this.granteeEmail,
    required this.status,
    this.requestedAt,
    this.emailVerifiedAt,
    this.decidedAt,
    this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final String batchUserId;
  final String granteeEmail;

  /// `pending_email`, `pending_approval`, `approved`, `rejected`, `revoked`
  /// or `expired`.
  final String status;
  final DateTime? requestedAt;
  final DateTime? emailVerifiedAt;
  final DateTime? decidedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  /// Finished grants (rejected/revoked/expired) return 404 on revoke.
  bool get canRevoke =>
      status == 'pending_email' ||
      status == 'pending_approval' ||
      status == 'approved';

  String get statusLabel => switch (status) {
    'pending_email' => 'Awaiting email check',
    'pending_approval' => 'Awaiting holder',
    'approved' => 'Approved',
    'rejected' => 'Rejected',
    'revoked' => 'Revoked',
    'expired' => 'Expired',
    _ => status.isEmpty ? 'Unknown' : status,
  };

  factory CertificateAccessGrant.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        DateTime.tryParse((json[key] ?? '').toString().trim());
    return CertificateAccessGrant(
      id: (json['id'] ?? '').toString().trim(),
      batchUserId: (json['batch_user_id'] ?? '').toString().trim(),
      granteeEmail: (json['grantee_email'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString().trim().toLowerCase(),
      requestedAt: date('requested_at'),
      emailVerifiedAt: date('email_verified_at'),
      decidedAt: date('decided_at'),
      expiresAt: date('expires_at'),
      revokedAt: date('revoked_at'),
    );
  }
}
