/// Organization-side models for the mandatory partial-SDC approval workflow.
///
/// Covers ONLY:
///   GET  /sdc/batches/{batch_id}/approvals
///   POST /sdc/approvals/{request_id}/decide
///
/// Out of scope (per handoff): superadmin dashboard, verifier UI,
/// SDC generation trigger, "who is fully verified" computation.
enum SdcPartialApprovalStatus { pending, approved, rejected, unknown }

SdcPartialApprovalStatus sdcPartialApprovalStatusFromJson(dynamic raw) {
  final String v = (raw ?? '').toString().trim().toLowerCase();
  return switch (v) {
    'pending' => SdcPartialApprovalStatus.pending,
    'approved' => SdcPartialApprovalStatus.approved,
    'rejected' => SdcPartialApprovalStatus.rejected,
    _ => SdcPartialApprovalStatus.unknown,
  };
}

String sdcPartialApprovalStatusToJson(SdcPartialApprovalStatus status) {
  return switch (status) {
    SdcPartialApprovalStatus.pending => 'pending',
    SdcPartialApprovalStatus.approved => 'approved',
    SdcPartialApprovalStatus.rejected => 'rejected',
    SdcPartialApprovalStatus.unknown => 'unknown',
  };
}

class SdcPartialApprovalRequest {
  const SdcPartialApprovalRequest({
    required this.id,
    required this.batchId,
    required this.orgId,
    required this.selectedUserIds,
    required this.status,
    this.requestedBy,
    required this.createdAt,
    this.decidedBy,
    this.decidedAt,
    this.decisionReason,
  });

  final String id;
  final String batchId;
  final String orgId;
  final List<String> selectedUserIds;
  final SdcPartialApprovalStatus status;
  final String? requestedBy;
  final String createdAt;
  final String? decidedBy;
  final String? decidedAt;
  final String? decisionReason;

  bool get isPending => status == SdcPartialApprovalStatus.pending;
  bool get isDecided =>
      status == SdcPartialApprovalStatus.approved ||
      status == SdcPartialApprovalStatus.rejected;

  SdcPartialApprovalRequest copyWith({
    String? id,
    String? batchId,
    String? orgId,
    List<String>? selectedUserIds,
    SdcPartialApprovalStatus? status,
    String? Function()? requestedBy,
    String? createdAt,
    String? Function()? decidedBy,
    String? Function()? decidedAt,
    String? Function()? decisionReason,
  }) {
    return SdcPartialApprovalRequest(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      orgId: orgId ?? this.orgId,
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
      status: status ?? this.status,
      requestedBy: requestedBy != null ? requestedBy() : this.requestedBy,
      createdAt: createdAt ?? this.createdAt,
      decidedBy: decidedBy != null ? decidedBy() : this.decidedBy,
      decidedAt: decidedAt != null ? decidedAt() : this.decidedAt,
      decisionReason: decisionReason != null
          ? decisionReason()
          : this.decisionReason,
    );
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((dynamic e) => e?.toString().trim() ?? '')
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static String? _readNullableString(dynamic raw) {
    if (raw == null) return null;
    final String s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory SdcPartialApprovalRequest.fromJson(Map<String, dynamic> json) {
    return SdcPartialApprovalRequest(
      id: (json['id'] ?? '').toString().trim(),
      batchId: (json['batch_id'] ?? json['batchId'] ?? '').toString().trim(),
      orgId: (json['org_id'] ?? json['orgId'] ?? '').toString().trim(),
      selectedUserIds: _readStringList(
        json['selected_user_ids'] ?? json['selectedUserIds'],
      ),
      status: sdcPartialApprovalStatusFromJson(json['status']),
      requestedBy: _readNullableString(
        json['requested_by'] ?? json['requestedBy'],
      ),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '')
          .toString()
          .trim(),
      decidedBy: _readNullableString(json['decided_by'] ?? json['decidedBy']),
      decidedAt: _readNullableString(json['decided_at'] ?? json['decidedAt']),
      decisionReason: _readNullableString(
        json['decision_reason'] ?? json['decisionReason'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'batch_id': batchId,
      'org_id': orgId,
      'selected_user_ids': selectedUserIds,
      'status': sdcPartialApprovalStatusToJson(status),
      'requested_by': requestedBy,
      'created_at': createdAt,
      'decided_by': decidedBy,
      'decided_at': decidedAt,
      'decision_reason': decisionReason,
    };
  }
}

/// An organization authorization for a SuperAdmin to generate a partial SDC.
class PartialSdcAuthorization {
  const PartialSdcAuthorization({
    required this.id,
    required this.batchUserId,
    required this.holderName,
    required this.status,
    required this.isValid,
    required this.items,
  });
  final String id;
  final String batchUserId;
  final String holderName;
  final String status;
  final bool isValid;
  final List<PartialSdcAuthorizationItem> items;

  factory PartialSdcAuthorization.fromJson(Map<String, dynamic> json) =>
      PartialSdcAuthorization(
        id: (json['id'] ?? '').toString(),
        batchUserId: (json['batch_user_id'] ?? '').toString(),
        holderName: (json['holder_name'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        isValid: json['is_valid'] != false,
        items: (json['items'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (Map e) => PartialSdcAuthorizationItem.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList(),
      );
}

class PartialSdcAuthorizationItem {
  const PartialSdcAuthorizationItem({
    required this.typeName,
    required this.currentState,
  });
  final String typeName;
  final String currentState;
  factory PartialSdcAuthorizationItem.fromJson(Map<String, dynamic> json) =>
      PartialSdcAuthorizationItem(
        typeName: (json['verification_type_name'] ?? '').toString(),
        currentState: (json['current_state'] ?? '').toString(),
      );
}
