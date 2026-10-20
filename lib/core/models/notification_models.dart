/// An in-app notification created for an organization
/// (new_flutter_trumarkz.md §13).
///
/// The backend currently only produces `batch_deleted` notifications when a
/// superadmin permanently removes one of the organization's batches, but
/// [notificationType] is a plain string on purpose: a new type needs no new
/// endpoint and no client change beyond the label.
class OrgNotification {
  const OrgNotification({
    required this.id,
    required this.notificationType,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.batchId,
  });

  final String id;
  final String notificationType;
  final String message;

  /// Historical reference to the batch that was deleted.
  ///
  /// The batch is already gone by the time the notification exists, so this
  /// id must never be used to open or fetch that batch — it will 404. Show
  /// [message] instead of linking into the deleted batch.
  final String? batchId;

  final bool isRead;
  final String createdAt;

  bool get isUnread => !isRead;

  bool get isBatchDeleted => notificationType.trim() == 'batch_deleted';

  DateTime? get createdAtDateTime => DateTime.tryParse(createdAt.trim());

  factory OrgNotification.fromJson(Map<String, dynamic> json) {
    return OrgNotification(
      id: (json['id'] ?? '').toString().trim(),
      notificationType: (json['notification_type'] ?? json['notificationType'] ?? '')
          .toString()
          .trim(),
      message: (json['message'] ?? '').toString().trim(),
      batchId: _readOptional(json['batch_id'] ?? json['batchId']),
      isRead:
          json['is_read'] == true ||
          json['isRead'] == true ||
          (json['is_read'] ?? json['isRead'])?.toString().trim() == 'true',
      createdAt:
          (json['created_at'] ?? json['createdAt'] ?? '').toString().trim(),
    );
  }

  OrgNotification copyWith({bool? isRead}) {
    return OrgNotification(
      id: id,
      notificationType: notificationType,
      message: message,
      batchId: batchId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// Result of `POST /verification/notifications/{id}/read`.
class NotificationReadResult {
  const NotificationReadResult({required this.id, required this.isRead});

  final String id;
  final bool isRead;

  factory NotificationReadResult.fromJson(Map<String, dynamic> json) {
    return NotificationReadResult(
      id: (json['id'] ?? '').toString().trim(),
      isRead:
          json['is_read'] == true ||
          json['isRead'] == true ||
          (json['is_read'] ?? json['isRead'])?.toString().trim() == 'true',
    );
  }
}

/// Result of `POST /verification/notifications/read-all`.
class MarkAllReadResult {
  const MarkAllReadResult({required this.markedCount});

  final int markedCount;

  factory MarkAllReadResult.fromJson(Map<String, dynamic> json) {
    final Object? raw = json['marked_count'] ?? json['markedCount'];
    return MarkAllReadResult(
      markedCount: raw is num
          ? raw.toInt()
          : int.tryParse(raw?.toString().trim() ?? '') ?? 0,
    );
  }
}

String? _readOptional(dynamic raw) {
  final String value = (raw ?? '').toString().trim();
  return value.isEmpty ? null : value;
}
