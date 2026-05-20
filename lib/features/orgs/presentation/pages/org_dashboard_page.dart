import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../../core/models/verification_models.dart';
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
    // Defer heavier loading so above-the-fold content (header/banner/actions)
    // can paint immediately.
    Future<void>.microtask(() async {
      final notifier = ref.read(verificationListNotifierProvider.notifier);
      await notifier.load(limit: 20);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.load(limit: 500);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final double topInset = MediaQuery.paddingOf(context).top;
    // Space for the floating bottom nav pill so content isn't hidden behind it.
    // Keep this a bit generous because the pill includes its own padding +
    // elevation shadow, and the Scaffold uses extendBody=true.
    const double kBottomNavHeight = 84.0;
    const double kNavPillMargin = 20.0;
    // Keep section-to-section spacing consistent. Note: quick-action icons
    // overflow upward, so the pills need extra headroom.
    const double kQuickActionOverflowPad = 16;
    const double kSectionGap = AppSpacing.x1 + kQuickActionOverflowPad;
    final double bottomScrollPadding =
        bottomInset + kBottomNavHeight + kNavPillMargin;

    final VerificationListState verificationState = ref.watch(
      verificationListNotifierProvider,
    );
    final VerificationListResponse? verification =
        verificationState.data.valueOrNull;
    final _DashboardSummary summary = _DashboardSummary.fromVerification(
      verification,
    );

    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomScrollPadding),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.x4,
              topInset + AppSpacing.x4,
              AppSpacing.x4,
              0,
            ),
            child:
                const _OrgDashboardHeader(
                      location: 'Kandivali',
                      description: "Lorem Ipsum has been the industry's...",
                      avatarAssetPath: 'assets/icons/dashbaord/profile.png',
                    )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 220.ms)
                    .slideY(
                      begin: 0.04,
                      duration: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
                child: const _OrgDashboardBanner(
                  assetPaths: <String>[
                    'assets/icons/dashbaord/ChatGPT Image May 19, 2026, 06_12_44 PM.png',
                    'assets/icons/dashbaord/ChatGPT Image May 19, 2026, 06_15_23 PM.png',
                    'assets/icons/dashbaord/ChatGPT Image May 19, 2026, 06_16_42 PM.png',
                  ],
                ),
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
            child: const _SectionLabel('Quick Actions')
                .animate()
                .fadeIn(delay: 120.ms, duration: 220.ms)
                .slideY(
                  begin: 0.04,
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x4,
              right: AppSpacing.x4,
              top: kQuickActionOverflowPad, // absorb overflow (top: -22)
            ),
            child:
                Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _QuickActionPill(
                                label: 'NEW BATCH',
                                subtitle: '',
                                topAssetPath:
                                    'assets/icons/dashbaord/new_batch.png',
                                onTap: () => context.go(
                                  AppRouter.batchTypeSelectionPath,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionPill(
                                label: 'REPORTS',
                                subtitle: '',
                                topAssetPath:
                                    'assets/icons/dashbaord/reports.png',
                                onTap: () =>
                                    context.go(AppRouter.appReportsPath),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionPill(
                                label: 'REGISTRY',
                                subtitle: '',
                                topAssetPath:
                                    'assets/icons/dashbaord/registry_final.png',
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
          const SizedBox(height: kSectionGap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            child: const _SectionLabel('Recent Batch Process'),
          ),
          const SizedBox(height: kSectionGap),
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
          else if (summary.recentBatches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: AppSpacing.x4,
              ),
              child: _DashboardEmptyState(
                title: 'No batches yet',
                message: 'Create your first batch to start processing records.',
                ctaLabel: 'Create your first batch',
                onCtaTap: () => context.go(AppRouter.batchTypeSelectionPath),
              ),
            )
          else
            ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 220,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x4,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: summary.recentBatches.length.clamp(0, 10),
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final _DashboardBatchItem batch =
                          summary.recentBatches[index];
                      return _RecentBatchCard(
                            batch: batch,
                            onTap: () {
                              final String batchId = batch.batchId;
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
                          .fadeIn(delay: (80 + index * 60).ms, duration: 220.ms)
                          .slideX(
                            begin: 0.05,
                            duration: 220.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
                )
                .animate()
                .fadeIn(delay: 180.ms, duration: 220.ms)
                .slideY(
                  begin: 0.04,
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                ),
          const SizedBox(height: AppSpacing.x5),
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 120,
                    child: Image.asset(
                      'assets/icons/dashbaord/quick_scan.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 160.ms, duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

class _OrgDashboardBanner extends StatefulWidget {
  const _OrgDashboardBanner({required this.assetPaths});

  final List<String> assetPaths;

  @override
  State<_OrgDashboardBanner> createState() => _OrgDashboardBannerState();
}

class _OrgDashboardBannerState extends State<_OrgDashboardBanner> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final int count = widget.assetPaths.length;
      if (count <= 1) return;
      _index = (_index + 1) % count;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> banners = widget.assetPaths
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    if (banners.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 223,
        child: PageView.builder(
          controller: _controller,
          itemCount: banners.length,
          onPageChanged: (int i) {
            _index = i;
            _resetTimer();
          },
          itemBuilder: (BuildContext context, int index) {
            return Image.asset(banners[index], fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 9,
        letterSpacing: 0.8,
        color: Color(0xFFBCBABA),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.onCtaTap,
  });

  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback onCtaTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.inbox_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            title,
            style: AppTypography.body2.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            message,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.x2),
          TextButton(onPressed: onCtaTap, child: Text(ctaLabel)),
        ],
      ),
    );
  }
}

class _OrgDashboardHeader extends StatelessWidget {
  const _OrgDashboardHeader({
    required this.location,
    required this.description,
    required this.avatarAssetPath,
  });

  final String location;
  final String description;
  final String avatarAssetPath;

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFF161616);
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.location_on, size: 26, color: iconColor),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      location,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        height: 20 / 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 7,
                        height: 9 / 7,
                        color: Color(0xFF888787),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 24,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _AvatarBadge(assetPath: avatarAssetPath),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
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
    required this.verifiedCount,
    required this.progressFraction,
    required this.status,
    required this.updatedAt,
    required this.isHumanVerification,
  });

  final String batchId;
  final String title;
  final int recordCount;
  final int verifiedCount;
  final double progressFraction;
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

    final double progress = agg.count > 0
        ? (agg.verifiedCount / agg.count).clamp(0.0, 1.0)
        : 0.0;

    return _DashboardBatchItem(
      batchId: agg.batchId,
      title: 'Batch $shortId',
      recordCount: agg.count,
      verifiedCount: agg.verifiedCount,
      progressFraction: progress,
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
    required this.subtitle,
    required this.onTap,
    this.topAssetPath,
  });

  static const double _pillHeight = 76;
  static const double _pillRadius = 12;
  static const double _iconSize = 52;
  static const double _iconTop = -14;

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? topAssetPath;

  @override
  Widget build(BuildContext context) {
    final String? asset = topAssetPath?.trim();
    final String subtitleText = subtitle.trim();
    return Semantics(
      label: label,
      hint: subtitleText.isEmpty ? null : subtitleText,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_pillRadius),
          child: SizedBox(
            height: _pillHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEFE),
                    borderRadius: BorderRadius.circular(_pillRadius),
                    border: Border.all(color: const Color(0xFFF5F5F5)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x40B8B8B8),
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          height: 12 / 9,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (subtitleText.isNotEmpty)
                        Text(
                          subtitleText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
                            height: 1.25,
                            color: Color(0xFFBCBABA),
                          ),
                        ),
                    ],
                  ),
                ),
                if (asset != null && asset.isNotEmpty)
                  Positioned(
                    top: _iconTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        asset,
                        width: _iconSize,
                        height: _iconSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentBatchCard extends StatelessWidget {
  const _RecentBatchCard({required this.batch, required this.onTap});

  final _DashboardBatchItem batch;
  final VoidCallback onTap;

  static const double _cardRadius = 18;
  static const String _humanAsset =
      'assets/icons/dashbaord/human_vericiation_final.png';

  @override
  Widget build(BuildContext context) {
    final _RecentStatus status = _RecentStatus.fromBatch(batch.status);
    const String typeAsset = _humanAsset;
    const Color navy = Color(0xFF0E2D64);
    const double kHeaderIconSize = 72;
    const double kHeaderIconRightInset = 12;
    const double kHeaderIconTopInset = 6;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 230,
              height: 212,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: const Color(0xFFF5F5F5), width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_cardRadius),
                      topRight: Radius.circular(_cardRadius),
                    ),
                    child: Container(
                      height: 84,
                      color: navy,
                      child: Stack(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              18,
                              16 + kHeaderIconSize + 12,
                              8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        batch.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          height: 16 / 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: kHeaderIconRightInset,
                            top: kHeaderIconTopInset,
                            child: _HeaderIllustration(
                              iconAsset: typeAsset,
                              tint: Colors.white.withAlpha(230),
                              size: kHeaderIconSize,
                            ),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 18,
                            child: _ViewDetailsButton(onTap: onTap),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Text(
                                'Current Status',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  height: 14 / 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF292727),
                                ),
                              ),
                              const Spacer(),
                              _StatusPill(label: status.label, status: status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _BigStatCard(
                                  value: '${batch.recordCount}',
                                  label: 'Total Entries',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BigStatCard(
                                  value: _compactTime(batch.updatedAt),
                                  label: 'Time Remaining',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _MiniProgressBar(value: batch.progressFraction),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _compactTime(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    final int days = diff.inDays;
    final int hours = diff.inHours.remainder(24);
    if (days <= 0) return '${diff.inHours}h';
    if (hours == 0) return '${days}d';
    return '${days}d ${hours}hrs';
  }
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'View Details',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 7,
              height: 9 / 7,
              fontWeight: FontWeight.w500,
              color: Color(0xFF292727),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.status});

  final String label;
  final _RecentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: status.pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 7,
          height: 9 / 7,
          fontWeight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              height: 20 / 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212020),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 8,
              height: 10 / 8,
              fontWeight: FontWeight.w500,
              color: Color(0xFF484444),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration({
    required this.iconAsset,
    required this.tint,
    this.size = 76,
  });

  final String iconAsset;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(iconAsset, fit: BoxFit.contain),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double trackWidth = constraints.maxWidth;
            final double fillWidth = trackWidth * clamped;
            return Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x33787878),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Container(
                  width: fillWidth,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2D64),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecentStatus {
  const _RecentStatus({
    required this.label,
    required this.pillBg,
    required this.textColor,
  });

  final String label;
  final Color pillBg;
  final Color textColor;

  factory _RecentStatus.fromBatch(_BatchStatus s) => switch (s) {
    _BatchStatus.processing => const _RecentStatus(
      label: 'Under Review',
      pillBg: Color(0xFFF1F1F1),
      textColor: Color(0xFF292727),
    ),
    _BatchStatus.complete => const _RecentStatus(
      label: 'Completed',
      pillBg: Color(0xFF299E11),
      textColor: Colors.white,
    ),
    _BatchStatus.alert => const _RecentStatus(
      label: 'Rejected',
      pillBg: Color(0xFFD73D09),
      textColor: Colors.white,
    ),
  };
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
