import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/network/api_client.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

/// Organization notifications, newest first.
///
/// The backend has no real-time delivery, so this is a plain
/// re-fetch-and-refresh provider: invalidate it to pick up new
/// notifications (new_flutter_trumarkz.md §13d).
final orgNotificationsProvider = FutureProvider.autoDispose<
  List<OrgNotification>
>((ref) async {
  return ref.read(notificationRepositoryProvider).getNotifications();
});

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  /// GET /verification/notifications
  ///
  /// [unreadOnly] filters to unread notifications, [limit] is capped by the
  /// backend to 1-200 and [offset] pages through the list.
  Future<List<OrgNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      'unread_only': unreadOnly ? 'true' : 'false',
      'limit': limit.clamp(1, 200).toString(),
      'offset': offset < 0 ? '0' : offset.toString(),
    };
    final Uri uri = Uri(
      path: '/verification/notifications',
      queryParameters: queryParameters,
    );
    final dynamic res = await _api.verificationGetAny(uri.toString());

    final List<dynamic> rawItems;
    if (res is List) {
      rawItems = res;
    } else if (res is Map) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(res);
      final dynamic data =
          json['data'] ??
          json['notifications'] ??
          json['items'] ??
          json['results'];
      rawItems = data is List ? data : const <dynamic>[];
    } else {
      rawItems = const <dynamic>[];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (Map e) => OrgNotification.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((OrgNotification item) => item.id.isNotEmpty)
        .toList();
  }

  /// POST /verification/notifications/{id}/read
  ///
  /// Throws [ApiException] with 404 when the id does not exist or belongs to
  /// another organization — the backend does not distinguish the two cases.
  Future<NotificationReadResult> markAsRead(String notificationId) async {
    final String id = notificationId.trim();
    if (id.isEmpty) {
      throw const ApiException(
        statusCode: null,
        message: 'Notification id is required.',
      );
    }
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/notifications/${Uri.encodeComponent(id)}/read',
      data: const <String, dynamic>{},
    );
    return NotificationReadResult.fromJson(res);
  }

  /// POST /verification/notifications/read-all
  ///
  /// Always applies to the calling organization's own unread notifications.
  /// Returns how many were actually flipped to read.
  Future<MarkAllReadResult> markAllAsRead() async {
    final Map<String, dynamic> res = await _api.verificationPost(
      '/verification/notifications/read-all',
      data: const <String, dynamic>{},
    );
    return MarkAllReadResult.fromJson(res);
  }
}
