import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../../core/models/notification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../../core/widgets/org_top_bar.dart';
import '../../application/notification_notifier.dart';

class NotificationCentrePage extends ConsumerStatefulWidget {
  const NotificationCentrePage({super.key});

  @override
  ConsumerState<NotificationCentrePage> createState() =>
      _NotificationCentrePageState();
}

class _NotificationCentrePageState extends ConsumerState<NotificationCentrePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The backend has no real-time delivery, so a resumed app is the
    // cheapest moment to pick up notifications created while away.
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(notificationNotifierProvider.notifier).refresh(showLoader: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String flow =
        GoRouterState.of(context).uri.queryParameters['flow']?.toLowerCase() ??
        '';
    final String backPath = switch (flow) {
      'individual' => AppRouter.individualIdentityPath,
      'org' => AppRouter.dashboardPath,
      _ => AppRouter.dashboardPath,
    };

    final bool isOrg = flow == 'org';
    if (isOrg) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          context.go(backPath);
        },
        child: Scaffold(
          backgroundColor: AppColors.brandBlue,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: OrgTopBar(
                    title: 'Notifications',
                    onBack: () => context.go(backPath),
                    showActions: false,
                  ),
                ),
                const SizedBox(height: 21),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: const _OrgNotificationsBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(backPath);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go(backPath),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Row(
            children: <Widget>[
              Image.asset('assets/icons/headers_app_icon.png', height: 24),
              const SizedBox(width: AppSpacing.x2),
              const Text('Notification Centre'),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.x4),
          children: const <Widget>[
            _UpdatesBody(),
          ],
        ),
      ),
    );
  }
}

/// Organization notifications list (new_flutter_trumarkz.md §13).
///
/// The backend only delivers notifications in-app — no email — and has no
/// push mechanism, so this list re-fetches on entry, on pull-to-refresh and
/// on a timer while the screen stays open.
class _OrgNotificationsBody extends ConsumerStatefulWidget {
  const _OrgNotificationsBody();

  @override
  ConsumerState<_OrgNotificationsBody> createState() =>
      _OrgNotificationsBodyState();
}

class _OrgNotificationsBodyState extends ConsumerState<_OrgNotificationsBody> {
  static const Duration _pollInterval = Duration(seconds: 30);

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificationNotifierProvider.notifier).refresh();
    });
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      ref.read(notificationNotifierProvider.notifier).refresh(showLoader: false);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final bool ok = await ref
        .read(notificationNotifierProvider.notifier)
        .markAllAsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'All notifications marked as read.'
              : 'Could not mark notifications as read. Please try again.',
        ),
      ),
    );
  }

  Future<void> _openNotification(OrgNotification notification) async {
    if (notification.isUnread) {
      await ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notification.id);
    }
    // `batch_id` is a historical reference to a permanently deleted batch —
    // opening that batch would 404. The message text is the whole story, so
    // there is nothing to navigate to here.
  }

  String _formatTimestamp(OrgNotification notification) {
    final DateTime? created = notification.createdAtDateTime;
    if (created == null) return notification.createdAt;
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(created);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${created.day}/${created.month}/${created.year}';
  }

  @override
  Widget build(BuildContext context) {
    final NotificationState state = ref.watch(notificationNotifierProvider);
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationNotifierProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x4,
            48,
            AppSpacing.x4,
            48 + safeBottom,
          ),
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.blueTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.bell,
                      color: AppColors.brandBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You are all caught up. We will let you know when '
                    'something needs your attention.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationNotifierProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4 + safeBottom,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Updates', style: AppTypography.heading1),
              ),
              if (state.hasUnread)
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(LucideIcons.checkCheck, size: 16),
                  label: const Text('Mark all read'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                    visualDensity: VisualDensity.compact,
                    textStyle: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          if (state.errorMessage != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.x3),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    LucideIcons.circleAlert,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.danger,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
          ],
          for (final OrgNotification notification in state.items) ...<Widget>[
            _NotificationCard(
              notification: notification,
              timestampLabel: _formatTimestamp(notification),
              onTap: () => _openNotification(notification),
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timestampLabel,
    required this.onTap,
  });

  final OrgNotification notification;
  final String timestampLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isUnread = notification.isUnread;
    return TMZCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification.isBatchDeleted
                  ? AppColors.dangerBg
                  : AppColors.blueTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.isBatchDeleted
                  ? LucideIcons.trash2
                  : LucideIcons.bell,
              color: notification.isBatchDeleted
                  ? AppColors.danger
                  : AppColors.brandBlue,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  notification.isBatchDeleted
                      ? 'Batch deleted'
                      : (notification.notificationType.isEmpty
                            ? 'Notification'
                            : notification.notificationType),
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  notification.message.isEmpty
                      ? 'No further details available.'
                      : notification.message,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: <Widget>[
                    Text(
                      timestampLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (isUnread)
                      TMZBadge.pending(label: 'NEW')
                    else
                      TMZBadge.manual(label: 'READ'),
                  ],
                ),
              ],
            ),
          ),
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brandBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpdatesBody extends StatelessWidget {
  const _UpdatesBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Updates', style: AppTypography.heading1),
        const SizedBox(height: AppSpacing.x3),
        TMZCard(
          onTap: () {},
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Credential verified',
                      style: AppTypography.heading2,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Your National ID was successfully verified on-chain.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Row(
                      children: <Widget>[
                        Text(
                          'Today',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TMZBadge.verified(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
