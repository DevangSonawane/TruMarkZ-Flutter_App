import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Space for the floating bottom nav pill so content isn't hidden behind it.
    final double bottomScrollPadding = bottomInset + 148;

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
      backgroundColor: AppColors.cardSurface,
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomScrollPadding),
        children: <Widget>[
          _HeroGreetingCard(
                name: displayName,
                isVerified: isVerified,
                registrationNumber: brn,
                isLoading: verificationState.data.isLoading,
                totalUsers: totalUsers,
                pending: summary.pending,
                verified: summary.verified,
                onTapSummary: () {},
              )
              .animate()
              .fadeIn(duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            child: const _SectionDividerTitle(text: 'QUICK ACTIONS')
                .animate()
                .fadeIn(delay: 120.ms, duration: 220.ms)
                .slideY(
                  begin: 0.04,
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            child:
                Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _QuickActionPill(
                                label: 'Batch',
                                topAssetPath:
                                    'assets/icons/dashbaord/3dicons-folder-new-dynamic-color.png',
                                onTap: () => context.go(
                                  AppRouter.batchTypeSelectionPath,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionPill(
                                label: 'Reports',
                                topAssetPath:
                                    'assets/icons/dashbaord/3dicons-copy-dynamic-color.png',
                                onTap: () =>
                                    context.go(AppRouter.appReportsPath),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionPill(
                                label: 'Registry',
                                topAssetPath:
                                    'assets/icons/dashbaord/3dicons-notebook-dynamic-gradient.png',
                                onTap: () =>
                                    context.go(AppRouter.appRegistryPath),
                              ),
                            ),
                          ],
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
          ),
          const SizedBox(height: AppSpacing.x3),
          if (verificationState.data.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.x4),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (verificationState.data.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              child: TMZCard(
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
              ),
            )
          else ...<Widget>[
            if (summary.recentBatches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x4,
                  vertical: AppSpacing.x4,
                ),
                child: Center(
                  child: Text(
                    'No batches yet.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            if (summary.recentBatches.isNotEmpty)
              _BatchPeekCarousel(
                    batches: summary.recentBatches,
                    onTapBatch: (String batchId) {
                      if (batchId.trim().isEmpty) {
                        context.push(AppRouter.batchTrackingDetailPath);
                        return;
                      }
                      context.push(
                        '${AppRouter.batchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(batchId)}',
                      );
                    },
                  )
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 220.ms)
                  .slideY(
                    begin: 0.04,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
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
    required this.isLoading,
    required this.totalUsers,
    required this.pending,
    required this.verified,
  });

  final String name;
  final VoidCallback onTapSummary;
  final bool isVerified;
  final String registrationNumber;
  final bool isLoading;
  final int totalUsers;
  final int pending;
  final int verified;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double heroHeight = (MediaQuery.sizeOf(context).height * 0.5).clamp(
      300.0,
      440.0,
    );

    final String subtitle = registrationNumber.trim().isEmpty
        ? 'BRN not available'
        : 'BRN-${registrationNumber.trim()}';

    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: heroHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0B2A55), Color(0xFF07162F)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withAlpha(70),
                          Colors.black.withAlpha(10),
                          Colors.black.withAlpha(110),
                        ],
                        stops: const <double>[0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: -80,
                        right: -70,
                        width: 220,
                        height: 220,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: <Color>[
                                const Color(0xFF1A6BFF).withAlpha(90),
                                const Color(0xFF1A6BFF).withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -90,
                        left: -80,
                        width: 240,
                        height: 240,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: <Color>[
                                const Color(0xFF22D3EE).withAlpha(50),
                                const Color(0xFF22D3EE).withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 14,
                  bottom: 40,
                  child: _HeroAccentGif(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x6,
                    topInset + AppSpacing.x6,
                    AppSpacing.x6,
                    AppSpacing.x4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.heading1.copyWith(
                                fontSize: 20,
                                height: 1.05,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const _VerifiedStatusPill(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      const _HeroSearchBar(),
                      const SizedBox(height: AppSpacing.x3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          fontSize: 13,
                          color: Colors.white.withAlpha(130),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Divider(color: Colors.white.withAlpha(35), height: 1),
                      const SizedBox(height: AppSpacing.x3),
                      _HeroKpiBar(
                        isLoading: isLoading,
                        totalUsers: totalUsers,
                        pending: pending,
                        verified: verified,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroAccentGif extends StatelessWidget {
  const _HeroAccentGif();

  static const String _assetPath = 'assets/icons/girl_on_computer.gif';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 180,
            height: 180,
            child: Image.asset(
              _assetPath,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

// Compatibility shim: older hot-reload sessions may still have an Element for the
// previous video-based hero background. Keeping this type prevents
// `Lookup failed: _controller` errors during hot reload/unmount.
class _HeroBackgroundVideo extends StatefulWidget {
  const _HeroBackgroundVideo();

  @override
  State<_HeroBackgroundVideo> createState() => _HeroBackgroundVideoState();
}

class _HeroBackgroundVideoState extends State<_HeroBackgroundVideo> {
  // Intentionally unused: only here for hot-reload compatibility.
  // ignore: unused_field
  final Object? _controller = null;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _HeroSearchBar extends StatefulWidget {
  const _HeroSearchBar();

  @override
  State<_HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends State<_HeroSearchBar> {
  static const List<String> _hints = <String>[
    'Search for batches',
    'Search for users',
    'Search in registry',
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withAlpha(34)),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.search, size: 18, color: Colors.white.withAlpha(200)),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> anim) {
                    final Animation<Offset> offset = Tween<Offset>(
                      begin: const Offset(0, 0.6),
                      end: Offset.zero,
                    ).animate(anim);
                    return ClipRect(
                      child: SlideTransition(
                        position: offset,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                  child: Text(
                    _hints[_index],
                    key: ValueKey<String>('h:$_index'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      fontSize: 13,
                      color: Colors.white.withAlpha(190),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedStatusPill extends StatelessWidget {
  const _VerifiedStatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.success.withAlpha(120), width: 0.8),
      ),
      child: Text(
        'VERIFIED',
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: const Color(0xFFBBF7D0),
        ),
      ),
    );
  }
}

class _HeroKpiBar extends StatelessWidget {
  const _HeroKpiBar({
    required this.isLoading,
    required this.totalUsers,
    required this.pending,
    required this.verified,
  });

  final bool isLoading;
  final int totalUsers;
  final int pending;
  final int verified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _HeroKpi(
            value: isLoading ? null : totalUsers,
            label: 'Total users',
            valueColor: Colors.white,
          ),
        ),
        Container(width: 1, height: 44, color: Colors.white.withAlpha(38)),
        Expanded(
          child: _HeroKpi(
            value: isLoading ? null : pending,
            label: 'Pending',
            valueColor: Colors.white,
          ),
        ),
        Container(width: 1, height: 44, color: Colors.white.withAlpha(38)),
        Expanded(
          child: _HeroKpi(
            value: isLoading ? null : verified,
            label: 'Verified',
            valueColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _HeroKpi extends StatelessWidget {
  const _HeroKpi({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final int? value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = AppTypography.heading1.copyWith(
      fontSize: 22,
      height: 1.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: value == null ? Colors.white.withAlpha(70) : valueColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value == null ? '—' : _formatNumber(value!), style: valueStyle),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.body2.copyWith(
            fontSize: 10,
            color: Colors.white.withAlpha(110),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    final String s = n.toString();
    final StringBuffer buf = StringBuffer();
    final int rem = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (i - rem) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _SectionDividerTitle extends StatelessWidget {
  const _SectionDividerTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: AppColors.divider.withAlpha(120))),
        const SizedBox(width: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: AppColors.divider.withAlpha(120))),
      ],
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
      agg.isHumanVerification = agg.isHumanVerification || _isLikelyHuman(u);

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
        .take(8)
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

  static bool _isLikelyHuman(VerificationUser u) {
    if (u.fullName.trim().isNotEmpty) return true;
    if (u.phoneNumber.trim().isNotEmpty) return true;
    if (u.email.trim().isNotEmpty) return true;
    if ((u.aadharNumber ?? '').trim().isNotEmpty) return true;
    if ((u.panNumber ?? '').trim().isNotEmpty) return true;
    if ((u.photoUrl ?? '').trim().isNotEmpty) return true;
    if (u.documents.isNotEmpty) return true;
    return false;
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
  bool isHumanVerification = false;
}

class _DashboardBatchItem {
  const _DashboardBatchItem({
    required this.batchId,
    required this.title,
    required this.recordCount,
    required this.status,
    required this.updatedAt,
    required this.isHumanVerification,
  });

  final String batchId;
  final String title;
  final int recordCount;
  final _BatchStatus status;
  final DateTime updatedAt;
  final bool isHumanVerification;

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
      updatedAt:
          _DashboardSummary._tryParseIso(agg.updatedAt) ?? DateTime.now(),
      isHumanVerification: agg.isHumanVerification,
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.label,
    required this.onTap,
    this.topAssetPath,
  });

  final String label;
  final VoidCallback onTap;
  final String? topAssetPath;

  @override
  Widget build(BuildContext context) {
    final String? asset = topAssetPath?.trim();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 108;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: cardWidth,
                  height: 70,
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.textSecondary.withAlpha(38),
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.05,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (asset != null && asset.isNotEmpty)
                  Positioned(
                    top: -12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        asset,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
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

typedef _BatchTapCallback = void Function(String batchId);

class _BatchPeekCarousel extends StatefulWidget {
  const _BatchPeekCarousel({required this.batches, required this.onTapBatch});

  final List<_DashboardBatchItem> batches;
  final _BatchTapCallback onTapBatch;

  @override
  State<_BatchPeekCarousel> createState() => _BatchPeekCarouselState();
}

class _BatchPeekCarouselState extends State<_BatchPeekCarousel> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batches = widget.batches;
    if (batches.isEmpty) return const SizedBox.shrink();

    final _DashboardBatchItem active =
        batches[_current.clamp(0, batches.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          child: const _SectionDividerTitle(text: 'RECENT BATCHES'),
        ),
        const SizedBox(height: AppSpacing.x1),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            itemCount: batches.length,
            onPageChanged: (int i) => setState(() => _current = i),
            itemBuilder: (BuildContext context, int i) {
              final bool isActive = i == _current;
              final _DashboardBatchItem batch = batches[i];
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _BatchPeekCard(
                    batch: batch,
                    onTap: () => widget.onTapBatch(batch.batchId),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.x1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          child: Column(
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  active.title,
                  key: ValueKey<String>('t:${active.batchId}'),
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _buildSubtitle(active),
                  key: ValueKey<String>('s:${active.batchId}'),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(batches.length, (int i) {
                  final bool activeDot = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: activeDot ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeDot
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withAlpha(64),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildSubtitle(_DashboardBatchItem b) {
    final String ago = _timeAgo(b.updatedAt);
    final String status = switch (b.status) {
      _BatchStatus.complete => 'verified',
      _BatchStatus.processing => 'processing',
      _BatchStatus.alert => 'needs review',
    };
    return '${b.recordCount} records $status · $ago';
  }

  String _timeAgo(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _BatchPeekCard extends StatelessWidget {
  const _BatchPeekCard({required this.batch, required this.onTap});

  final _DashboardBatchItem batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _BatchCardStyle style = _BatchCardStyle.fromStatus(batch.status);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: style.bgGradient,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(18), width: 0.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              height: 112,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  12,
                  batch.isHumanVerification ? 64 : 14,
                  12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            batch.title,
                            style: AppTypography.body2.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${batch.recordCount} records',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withAlpha(200),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(batch.updatedAt),
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              color: Colors.white.withAlpha(140),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: style.accent.withAlpha(30),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: style.accent.withAlpha(70),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              style.label,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: style.accent,
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!batch.isHumanVerification)
            Positioned(
              right: -12,
              top: -14,
              child: Image.asset(
                'assets/icons/dashbaord/3dicons-folder-new-dynamic-color.png',
                height: 88,
                fit: BoxFit.contain,
              ),
            )
          else
            Positioned(
              right: -12,
              top: -18,
              child: Image.asset(
                'assets/icons/dashbaord/3dicons-boy-dynamic-color.png',
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _BatchCardStyle {
  const _BatchCardStyle({
    required this.bgGradient,
    required this.accent,
    required this.icon,
    required this.label,
  });

  final List<Color> bgGradient;
  final Color accent;
  final IconData icon;
  final String label;

  factory _BatchCardStyle.fromStatus(_BatchStatus s) => switch (s) {
    _BatchStatus.complete => const _BatchCardStyle(
      bgGradient: <Color>[Color(0xFF0A2A1A), Color(0xFF052E10)],
      accent: Color(0xFF4ADE80),
      icon: Icons.check_circle_outline_rounded,
      label: 'Complete',
    ),
    _BatchStatus.processing => const _BatchCardStyle(
      bgGradient: <Color>[Color(0xFF0A1A3A), Color(0xFF051028)],
      accent: Color(0xFF4DAAFF),
      icon: Icons.sync_rounded,
      label: 'Processing',
    ),
    _BatchStatus.alert => const _BatchCardStyle(
      bgGradient: <Color>[Color(0xFF2A1A0A), Color(0xFF1A0E04)],
      accent: Color(0xFFFFB547),
      icon: Icons.warning_amber_rounded,
      label: 'Needs review',
    ),
  };
}

enum _BatchStatus { complete, processing, alert }
