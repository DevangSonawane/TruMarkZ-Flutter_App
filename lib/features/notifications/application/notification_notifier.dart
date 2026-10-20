import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/network/api_client.dart';
import '../data/notification_repository.dart';

class NotificationState {
  const NotificationState({
    this.items = const <OrgNotification>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<OrgNotification> items;
  final bool isLoading;
  final String? errorMessage;

  int get unreadCount => items.where((OrgNotification n) => n.isUnread).length;

  bool get hasUnread => unreadCount > 0;

  NotificationState copyWith({
    List<OrgNotification>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(ref.read(notificationRepositoryProvider));
    });

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._repo) : super(const NotificationState());

  final NotificationRepository _repo;

  /// Loads the organization's notifications.
  ///
  /// There is no real-time delivery in the backend, so this is called on
  /// entry to the notification centre, on pull-to-refresh, and on a timer
  /// while the screen is visible.
  Future<void> refresh({bool showLoader = true}) async {
    if (showLoader) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final List<OrgNotification> items = await _repo.getNotifications();
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Marks a single notification as read.
  Future<bool> markAsRead(String notificationId) async {
    final String id = notificationId.trim();
    if (id.isEmpty) return false;

    // Optimistically flip the local copy so the indicator reacts instantly;
    // the server call below is the source of truth.
    final List<OrgNotification> optimistic = <OrgNotification>[
      for (final OrgNotification item in state.items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    state = state.copyWith(items: optimistic, clearError: true);

    try {
      await _repo.markAsRead(id);
      return true;
    } on ApiException catch (e) {
      // Roll back to the server state, then surface the failure.
      await refresh(showLoader: false);
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      await refresh(showLoader: false);
      state = state.copyWith(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  /// Marks every unread notification as read.
  Future<bool> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      final List<OrgNotification> updated = <OrgNotification>[
        for (final OrgNotification item in state.items) item.copyWith(isRead: true),
      ];
      state = state.copyWith(items: updated, clearError: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}
