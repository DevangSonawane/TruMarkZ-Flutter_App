import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../../core/models/verification_models.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../application/verification_list_notifier.dart';

class OrgDashboardPage extends ConsumerStatefulWidget {
  const OrgDashboardPage({super.key});

  @override
  ConsumerState<OrgDashboardPage> createState() => _OrgDashboardPageState();
}

class _OrgDashboardPageState extends ConsumerState<OrgDashboardPage> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    Future<void>.microtask(
      () =>
          ref.read(verificationListNotifierProvider.notifier).load(limit: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final profile = authAsync.value?.userProfile;
    final String displayName =
        profile?.organizationName?.trim().isNotEmpty == true
        ? profile!.organizationName!.trim()
        : (profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!.trim()
              : 'User');
    final bool isVerified = profile?.isVerified == true;
    final String brn =
        profile?.businessRegistrationNumber?.trim().isNotEmpty == true
        ? profile!.businessRegistrationNumber!.trim()
        : '';

    final VerificationListState verificationState = ref.watch(
      verificationListNotifierProvider,
    );
    final VerificationListResponse? verification =
        verificationState.data.valueOrNull;
    final _DashboardSummary summary = _DashboardSummary.fromVerification(
      verification,
    );
    final int totalUsers = verification?.total ?? 0;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            Image.asset(
              'assets/icons/headers_app_icon.png',
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppSpacing.x2),
            Text(
              'TruMarkZ',
              style: AppTypography.heading2.copyWith(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRouter.notificationsPath),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: AppSpacing.x3),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x3,
          AppSpacing.x4,
          AppSpacing.x8,
        ),
        children: <Widget>[
          _HeroGreetingCard(
                name: displayName,
                isVerified: isVerified,
                registrationNumber: brn,
                onTapSummary: () {},
              )
              .animate()
              .fadeIn(duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x4),
          _KpiScrollCards(
                isLoading: verificationState.data.isLoading,
                totalUsers: totalUsers,
                pendingVerifications: summary.pending,
                verifiedUsers: summary.verified,
              )
              .animate()
              .fadeIn(delay: 60.ms, duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x6),
          Row(
                children: <Widget>[
                  Text('Quick Actions', style: AppTypography.heading2),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 120.ms, duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x3),
          GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.x3,
                crossAxisSpacing: AppSpacing.x3,
                childAspectRatio: 1.28,
                children: <Widget>[
                  _QuickActionCard(
                    label: 'New Batch',
                    icon: Icons.drive_folder_upload_outlined,
                    onTap: () => context.go(AppRouter.batchTypeSelectionPath),
                  ),
                  _QuickActionCard(
                    label: 'Create Credentials',
                    icon: Icons.badge_outlined,
                    onTap: () => context.go(AppRouter.walletPath),
                  ),
                  _QuickActionCard(
                    label: 'View Reports',
                    icon: Icons.description_outlined,
                    onTap: () => context.go(AppRouter.appReportsPath),
                  ),
                  _QuickActionCard(
                    label: 'Registry Search',
                    icon: Icons.fact_check_outlined,
                    onTap: () => context.go(AppRouter.appRegistryPath),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 120.ms, duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x6),
          Row(
                children: <Widget>[
                  Text('Recent Batches', style: AppTypography.heading2),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Filter',
                    onPressed: () {},
                    icon: const Icon(Icons.sort_rounded),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 180.ms, duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x2),
          if (verificationState.data.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.x4),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (verificationState.data.hasError)
            TMZCard(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Text(
                      'Unable to load recent batches',
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(verificationListNotifierProvider.notifier)
                        .load(limit: 500),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            for (final _DashboardBatchItem item
                in summary.recentBatches) ...<Widget>[
              _BatchTile(
                title: item.title,
                subtitle: '${item.recordCount} records',
                status: item.status,
                onTap: item.batchId.trim().isEmpty
                    ? () => context.push(AppRouter.batchTrackingDetailPath)
                    : () => context.push(
                        '${AppRouter.batchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(item.batchId)}',
                      ),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            if (summary.recentBatches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
                child: Center(
                  child: Text(
                    'No batches yet.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HeroGreetingCard extends StatelessWidget {
  const _HeroGreetingCard({
    required this.name,
    required this.onTapSummary,
    required this.isVerified,
    required this.registrationNumber,
  });

  final String name;
  final VoidCallback onTapSummary;
  final bool isVerified;
  final String registrationNumber;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pills = <Widget>[
      _HeroPill(label: isVerified ? 'Verified' : 'Pending'),
      if (registrationNumber.trim().isNotEmpty)
        _HeroPill(label: 'Reg: ${registrationNumber.trim()}'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 170),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.brandBlue, AppColors.deepNavy],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.brandBlue.withAlpha(80),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Good morning, $name 👋',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 22,
                        height: 1.1,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Here's your verification summary.",
                      style: AppTypography.body2.copyWith(
                        fontSize: 13,
                        color: Colors.white.withAlpha(191),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: pills,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              const _HeroIllustration(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    final Widget pulse =
        Container(
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent.withAlpha(36),
                shape: BoxShape.circle,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.05, 1.05),
              duration: 900.ms,
              curve: Curves.easeInOut,
            )
            .fade(
              begin: 0.45,
              end: 0.9,
              duration: 900.ms,
              curve: Curves.easeInOut,
            );

    final Widget mainTile = Transform.rotate(
      angle: 0.21,
      child: _FrostedTile(
        width: 96,
        height: 96,
        radius: 14,
        borderAlpha: 77,
        backgroundAlpha: 26,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            const Center(
              child: Icon(
                Icons.verified_user_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget secondaryTile = Positioned(
      bottom: -8,
      left: -8,
      child: Transform.rotate(
        angle: -0.21,
        child: _FrostedTile(
          width: 64,
          height: 64,
          radius: 14,
          borderAlpha: 51,
          backgroundAlpha: 36,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    return SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(child: pulse),
              secondaryTile,
              mainTile,
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1200.ms, curve: Curves.easeInOut)
        .rotate(
          begin: 0,
          end: 0.01,
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _FrostedTile extends StatelessWidget {
  const _FrostedTile({
    required this.width,
    required this.height,
    required this.radius,
    required this.borderAlpha,
    required this.backgroundAlpha,
    required this.child,
  });

  final double width;
  final double height;
  final double radius;
  final int borderAlpha;
  final int backgroundAlpha;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(backgroundAlpha),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withAlpha(borderAlpha)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _KpiScrollCards extends StatelessWidget {
  const _KpiScrollCards({
    required this.isLoading,
    required this.totalUsers,
    required this.pendingVerifications,
    required this.verifiedUsers,
  });

  final bool isLoading;
  final int totalUsers;
  final int pendingVerifications;
  final int verifiedUsers;

  static const double _gap = AppSpacing.x3;
  static const double _minCardWidth = 140;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxWidth;
        final double cardWidth = ((available - (_gap * 2)) / 3).clamp(
          _minCardWidth,
          double.infinity,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x2),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: cardWidth,
                  child: _KpiStatCard(
                    label: 'Total Users',
                    value: isLoading ? '—' : totalUsers.toString(),
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: cardWidth,
                  child: _KpiStatCard(
                    label: 'Pending Verifications',
                    value: isLoading ? '—' : pendingVerifications.toString(),
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: cardWidth,
                  child: _KpiStatCard(
                    label: 'Verified',
                    value: isLoading ? '—' : verifiedUsers.toString(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardSummary {
  const _DashboardSummary({
    required this.pending,
    required this.verified,
    required this.failed,
    required this.activeBatches,
    required this.recentBatches,
  });

  final int pending;
  final int verified;
  final int failed;
  final int activeBatches;
  final List<_DashboardBatchItem> recentBatches;

  static _DashboardSummary fromVerification(VerificationListResponse? data) {
    if (data == null) {
      return const _DashboardSummary(
        pending: 0,
        verified: 0,
        failed: 0,
        activeBatches: 0,
        recentBatches: <_DashboardBatchItem>[],
      );
    }

    final Map<String, _BatchAgg> byBatch = <String, _BatchAgg>{};
    for (final VerificationUser u in data.users) {
      final String batchId = u.batchId.trim();
      final _BatchAgg agg = byBatch.putIfAbsent(
        batchId,
        () => _BatchAgg(batchId: batchId),
      );
      agg.count++;
      agg.updatedAt = _maxIso(agg.updatedAt, u.updatedAt);

      final String s = u.verificationStatus.trim();
      if (s == 'failed') {
        agg.failedCount++;
      } else if (s == 'pending_verification' || s == 'pending') {
        agg.pendingCount++;
      } else if (s == 'verified') {
        agg.verifiedCount++;
      }
    }

    final List<_BatchAgg> recent =
        byBatch.values.where((a) => a.batchId.isNotEmpty).toList()
          ..sort((a, b) => _compareIsoDesc(a.updatedAt, b.updatedAt));

    final List<_DashboardBatchItem> recentTiles = recent
        .take(3)
        .map(_DashboardBatchItem.fromAgg)
        .toList();

    final int active = byBatch.values
        .where((a) => a.batchId.isNotEmpty)
        .where((a) => a.pendingCount > 0)
        .length;

    return _DashboardSummary(
      pending: data.pending,
      verified: data.verified,
      failed: data.failed,
      activeBatches: active,
      recentBatches: recentTiles,
    );
  }

  static int _compareIsoDesc(String? a, String? b) {
    final DateTime? da = _tryParseIso(a);
    final DateTime? db = _tryParseIso(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  }

  static String? _maxIso(String? a, String? b) {
    final DateTime? da = _tryParseIso(a);
    final DateTime? db = _tryParseIso(b);
    if (da == null) return b;
    if (db == null) return a;
    return db.isAfter(da) ? b : a;
  }

  static DateTime? _tryParseIso(String? s) {
    if (s == null) return null;
    final String t = s.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }
}

class _BatchAgg {
  _BatchAgg({required this.batchId});

  final String batchId;
  int count = 0;
  int pendingCount = 0;
  int verifiedCount = 0;
  int failedCount = 0;
  String? updatedAt;
}

class _DashboardBatchItem {
  const _DashboardBatchItem({
    required this.batchId,
    required this.title,
    required this.recordCount,
    required this.status,
  });

  final String batchId;
  final String title;
  final int recordCount;
  final _BatchStatus status;

  factory _DashboardBatchItem.fromAgg(_BatchAgg agg) {
    final String shortId = agg.batchId.length <= 10
        ? agg.batchId
        : agg.batchId.substring(0, 10);

    final _BatchStatus status = agg.failedCount > 0
        ? _BatchStatus.alert
        : (agg.pendingCount > 0
              ? _BatchStatus.processing
              : _BatchStatus.complete);

    return _DashboardBatchItem(
      batchId: agg.batchId,
      title: 'Batch $shortId',
      recordCount: agg.count,
      status: status,
    );
  }
}

class _KpiStatCard extends StatelessWidget {
  const _KpiStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF6FF)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x14),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body2.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  value,
                  style: AppTypography.display1.copyWith(
                    fontSize: 28,
                    height: 1.0,
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TMZCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.brandBlue, size: 20),
          ),
          const SizedBox(height: AppSpacing.x3),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BatchStatus { complete, processing, alert }

class _BatchTile extends StatelessWidget {
  const _BatchTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final _BatchStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TMZBadge badge = switch (status) {
      _BatchStatus.complete => TMZBadge.complete(),
      _BatchStatus.processing => TMZBadge.processing(),
      _BatchStatus.alert => TMZBadge.alert(),
    };

    return TMZCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x2,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textTertiary,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.body2.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: scheme.onSurface.withAlpha(150),
          ),
        ),
        trailing: badge,
      ),
    );
  }
}
