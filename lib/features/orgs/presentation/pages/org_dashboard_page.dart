import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/models/verification_models.dart';
import '../../../../core/services/batch_name_store.dart';
import '../../../../core/widgets/tmz_card.dart';
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
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final dynamic profile = authAsync.value?.userProfile;
    final String displayName =
        profile?.organizationName?.trim().isNotEmpty == true
        ? profile!.organizationName!.trim()
        : (profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!.trim()
              : 'Organisation');
    final VerificationListState verificationState = ref.watch(
      verificationListNotifierProvider,
    );
    final VerificationListResponse? verification =
        verificationState.data.valueOrNull;
    final Map<String, String> savedBatchNames = ref.watch(
      batchNameStoreProvider,
    );
    final _DashboardSummary summary = _DashboardSummary.fromVerification(
      verification,
      savedBatchNames: savedBatchNames,
    );

    final double safeTop = MediaQuery.paddingOf(context).top;
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    const double figmaWidth = 402;
    final double sideInset = math.max(0, (screenWidth - figmaWidth) / 2);
    const double navHeight = 71.016;
    final double headerTop = safeTop; // Figma y=44 includes status bar
    final double welcomeTop = safeTop + 54; // 98 - 44
    final double drawerTop = safeTop + 111; // 155 - 44
    final double bgTop = safeTop + 211; // 255 - 44
    final double topSectionHeight = safeTop + 375; // 419 - 44

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: AppColors.brandBlue)),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: topSectionHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: bgTop,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.pageBg,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: sideInset + 16,
                        right: sideInset + 16,
                        top: headerTop,
                        height: 40,
                        child: _HomeHeader(
                          locationLine1: 'Kandivali, Mumbai',
                          locationLine2: 'Asynk Pvt Ltd',
                          avatarAssetPath: 'assets/icons/dashbaord/profile.png',
                          onAlertsTap: () =>
                              context.go(AppRouter.notificationsPath),
                          onProfileTap: () =>
                              context.go(AppRouter.settingsPath),
                        ),
                      ),
                      Positioned(
                        left: sideInset + 26,
                        top: welcomeTop,
                        child: _WelcomeMessage(
                          greeting: 'Welcome back,',
                          name: displayName,
                        ),
                      ),
                      Positioned(
                        left: sideInset + 16,
                        right: sideInset + 16,
                        top: drawerTop,
                        child: _HomeDrawerCard(
                          summary: summary,
                          onTapNewBatch: () =>
                              context.go(AppRouter.batchTypeSelectionPath),
                          onTapScanQr: () =>
                              context.go(AppRouter.qrScannerPath),
                          onTapReports: () =>
                              context.go(AppRouter.appReportsPath),
                          onTapRegistry: () =>
                              context.go(AppRouter.appRegistryPath),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.pageBg,
                  padding: EdgeInsets.fromLTRB(
                    sideInset + 16,
                    0,
                    sideInset + 16,
                    0,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: _SectionTitle('RECENT BATCH PROCESS'),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRouter.batchProgressPath),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.brandBlue,
                        ),
                        child: const Text(
                          'Certificates',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.pageBg,
                  padding: EdgeInsets.fromLTRB(
                    sideInset + 16,
                    12,
                    sideInset + 16,
                    0,
                  ),
                  child: _RecentSectionBody(
                    verificationState: verificationState,
                    summary: summary,
                    onTapBatch: (String batchId) => context.push(
                      AppRouter.appBatchTrackingDetailPath,
                      extra: batchId,
                    ),
                    onRetry: () => ref
                        .read(verificationListNotifierProvider.notifier)
                        .load(limit: 500),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.pageBg,
                  height: navHeight + safeBottom + 140,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentSectionBody extends StatelessWidget {
  const _RecentSectionBody({
    required this.verificationState,
    required this.summary,
    required this.onTapBatch,
    required this.onRetry,
  });

  final VerificationListState verificationState;
  final _DashboardSummary summary;
  final ValueChanged<String> onTapBatch;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (verificationState.data.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x4),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (verificationState.data.hasError) {
      return TMZCard(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.x3),
            const Expanded(
              child: Text(
                'Unable to load recent batches',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    return _RecentBatchList(batches: summary.recentBatches, onTap: onTapBatch);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.locationLine1,
    required this.locationLine2,
    required this.avatarAssetPath,
    this.onAlertsTap,
    this.onProfileTap,
  });

  final String locationLine1;
  final String locationLine2;
  final String avatarAssetPath;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/icons/figma/header_location.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 123,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      locationLine1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 17.5 / 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      locationLine2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        height: 16.5 / 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.03,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 14.125,
                height: 35,
                child: Align(
                  alignment: const Alignment(0, -0.15),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: SvgPicture.asset(
                      'assets/icons/figma/header_chevron.svg',
                      width: 10.125,
                      height: 10.125,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onAlertsTap,
          icon: SvgPicture.asset(
            'assets/icons/figma/header_bell.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: ClipOval(
                child: Image.asset(avatarAssetPath, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          greeting,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.2571,
            height: 18.3857 / 12.2571,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.0359,
            color: Colors.white,
          ),
        ),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22.2857,
            height: 19.5 / 22.2857,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        height: 17.75 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.18,
        color: Color(0xFF323232),
      ),
    );
  }
}

class _HomeDrawerCard extends StatelessWidget {
  const _HomeDrawerCard({
    required this.summary,
    required this.onTapNewBatch,
    required this.onTapScanQr,
    required this.onTapReports,
    required this.onTapRegistry,
  });

  final _DashboardSummary summary;
  final VoidCallback onTapNewBatch;
  final VoidCallback onTapScanQr;
  final VoidCallback onTapReports;
  final VoidCallback onTapRegistry;

  static const Color _metricTrack = Color(0xFF323232);
  static const Color _metricGreen = Color(0xFF00DDA3);
  static const Color _metricOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final int verified = summary.verified;
    final int pending = summary.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(15, 26.64, 16, 23.48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 313.2232,
            height: 63.7505,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: 0,
                  width: 145.3504,
                  child: _MetricTile(
                    label: 'Verified',
                    value: verified,
                    indicatorColor: _metricGreen,
                    trackColor: _metricTrack,
                    fraction: 0.7719299258572772,
                  ),
                ),
                Positioned(
                  left: 145.3504 + 22.1644,
                  top: 0,
                  width: 145.7084,
                  child: _MetricTile(
                    label: 'Pending',
                    value: pending,
                    indicatorColor: _metricOrange,
                    trackColor: _metricTrack,
                    fraction: 0.32631579555143664,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 31),
          // Figma quick actions row is a fixed 339.1047px layout. Scale it down
          // only when needed so it never clips on smaller devices, while
          // remaining pixel-perfect at the 402px Figma width.
          Align(
            alignment: Alignment.topLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 339.1047,
                height: 87.1341,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 13.5524,
                      top: 0,
                      child: _QuickActionCircle(
                        label: 'New Batch',
                        svgAssetPath: 'assets/icons/figma/qa_new_batch.svg',
                        iconSize: 36.66,
                        onTap: onTapNewBatch,
                      ),
                    ),
                    Positioned(
                      left: 97.5524,
                      top: 0,
                      child: _QuickActionCircle(
                        label: 'Scan QR',
                        svgAssetPath: 'assets/icons/figma/qa_scan_qr.svg',
                        iconSize: 25.662,
                        onTap: onTapScanQr,
                      ),
                    ),
                    Positioned(
                      left: 181.5524,
                      top: 0,
                      child: _QuickActionCircle(
                        label: 'Reports',
                        svgAssetPath: 'assets/icons/figma/qa_reports.svg',
                        iconSize: 25.662,
                        onTap: onTapReports,
                      ),
                    ),
                    Positioned(
                      left: 265.5524,
                      top: 0,
                      child: _QuickActionCircle(
                        label: 'Registry',
                        svgAssetPath: 'assets/icons/figma/qa_registry.svg',
                        iconSize: 25.662,
                        onTap: onTapRegistry,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.trackColor,
    required this.indicatorColor,
    required this.fraction,
  });

  final String label;
  final int value;
  final Color trackColor;
  final Color indicatorColor;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    const double barHeight = 6.12002;
    const double barRadius = 3.06001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.2800,
            height: 17.2821 / 14.2800,
            fontWeight: FontWeight.w500,
            color: Color(0xFF323232),
          ),
        ),
        Text(
          _formatMetricValue(value),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            height: 24 / 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0B0F19),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double barWidth = constraints.maxWidth;
            return SizedBox(
              width: barWidth,
              height: barHeight,
              child: Stack(
                children: <Widget>[
                  Container(
                    height: barHeight,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: trackColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(barRadius),
                    ),
                  ),
                  Container(
                    height: barHeight,
                    width: (barWidth * fraction).clamp(0, barWidth),
                    decoration: BoxDecoration(
                      color: indicatorColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(barRadius),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

String _formatMetricValue(int value) {
  // Figma shows full comma-grouped numbers (e.g. 15,615) rather than compact K/M.
  final int v = value.abs();
  final String s = v.toString();
  final String withCommas = s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return value < 0 ? '-$withCommas' : withCommas;
}

class _QuickActionCircle extends StatelessWidget {
  const _QuickActionCircle({
    required this.label,
    required this.svgAssetPath,
    required this.onTap,
    required this.iconSize,
  });

  final String label;
  final String svgAssetPath;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 60,
          height: 87.13,
          child: Column(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: 0.2),
                      offset: const Offset(0, 4.5671),
                      blurRadius: 6.8506,
                      spreadRadius: -4.5671,
                    ),
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: 0.2),
                      offset: const Offset(0, 11.4177),
                      blurRadius: 17.1265,
                      spreadRadius: -3.4253,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    svgAssetPath,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9.1341),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.9946,
                  height: 17.1265 / 10.9946,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBatchList extends StatelessWidget {
  const _RecentBatchList({required this.batches, required this.onTap});

  final List<_DashboardBatchItem> batches;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final List<_DashboardBatchItem> tiles = batches.isEmpty
        ? <_DashboardBatchItem>[
            _DashboardBatchItem(
              batchId: 'TR-98421',
              title: 'IN-North Logistics',
              recordCount: 4500,
              verifiedCount: 3402,
              progressFraction: 0.74,
              status: _BatchStatus.processing,
              updatedAt: DateTime.now().subtract(const Duration(days: 2)),
              isHumanVerification: true,
            ),
            _DashboardBatchItem(
              batchId: 'TR-98421',
              title: 'IN-North Logistics',
              recordCount: 840,
              verifiedCount: 840,
              progressFraction: 1,
              status: _BatchStatus.complete,
              updatedAt: DateTime.now().subtract(const Duration(days: 4)),
              isHumanVerification: true,
            ),
            _DashboardBatchItem(
              batchId: 'TR-98421',
              title: 'IN-North Logistics',
              recordCount: 840,
              verifiedCount: 840,
              progressFraction: 1,
              status: _BatchStatus.complete,
              updatedAt: DateTime.now().subtract(const Duration(days: 4)),
              isHumanVerification: true,
            ),
          ]
        : batches;

    return Column(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          _RecentBatchCard(
            batch: tiles[i],
            onTap: () => onTap(tiles[i].batchId),
          ),
          if (i != tiles.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RecentBatchCard extends StatelessWidget {
  const _RecentBatchCard({required this.batch, required this.onTap});

  final _DashboardBatchItem batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String badgeText = switch (batch.status) {
      _BatchStatus.processing => 'PROCESSING',
      _BatchStatus.complete => 'VERIFIED',
      _BatchStatus.alert => 'ALERT',
    };
    final Color badgeFg = switch (batch.status) {
      _BatchStatus.processing => AppColors.brandBlue,
      _BatchStatus.complete => const Color(0xFF059669),
      _BatchStatus.alert => AppColors.danger,
    };
    final Color badgeBg = switch (batch.status) {
      _BatchStatus.processing => AppColors.brandBlue.withValues(alpha: 0.10),
      _BatchStatus.complete => const Color(0xFFECFDF5),
      _BatchStatus.alert => AppColors.badgeRevokedBg,
    };
    final double badgeRadius = switch (batch.status) {
      _BatchStatus.processing => 4.0,
      _BatchStatus.complete => 4.288000106811523,
      _BatchStatus.alert => 4.0,
    };
    final EdgeInsets badgePadding = switch (batch.status) {
      _BatchStatus.processing => const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      _BatchStatus.complete => const EdgeInsets.symmetric(
        horizontal: 8.576000213623047,
        vertical: 2.1440000534057617,
      ),
      _BatchStatus.alert => const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
    };
    final double badgeLetterSpacing = switch (batch.status) {
      _BatchStatus.processing => -0.25,
      _BatchStatus.complete => 0.1465625036507845,
      _BatchStatus.alert => -0.25,
    };

    final int processed = batch.verifiedCount.clamp(0, batch.recordCount);
    final int total = batch.recordCount.clamp(1, 1 << 31);
    final int pct = (batch.progressFraction * 100).round().clamp(0, 100);
    final bool isProcessing = batch.status == _BatchStatus.processing;
    final String leftIcon = switch (batch.status) {
      _BatchStatus.processing => 'assets/icons/figma/batch_icon_processing.svg',
      _BatchStatus.complete => 'assets/icons/figma/batch_icon_verified.svg',
      _BatchStatus.alert => 'assets/icons/figma/batch_icon_processing.svg',
    };
    final Color leftBg = switch (batch.status) {
      _BatchStatus.processing => AppColors.brandBlue.withValues(alpha: 0.05),
      _BatchStatus.complete => AppColors.success.withValues(alpha: 0.10),
      _BatchStatus.alert => AppColors.danger.withValues(alpha: 0.08),
    };

    final Color borderColor = const Color(0xFFE2E8F0).withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: leftBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          leftIcon,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            badgeFg,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 88),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Batch: ${batch.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Rounded',
                                  fontSize: 14,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.013671875,
                                  color: Color(0xFF0B0F19),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Batch ID: ${_truncateBatchId(batch.batchId)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Rounded',
                                  fontSize: 11,
                                  height: 16.5 / 11,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.01,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Status: ${_statusLabel(batch.status)}',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 11,
                            height: 16.5 / 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.03,
                            color: Color(0xFF0B0F19),
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          fontSize: 11,
                          height: 16.5 / 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: batch.progressFraction.clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.divider.withValues(
                        alpha: 0.35,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(badgeFg),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isProcessing)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${_formatCompact(processed)} / ${_formatCompact(total)} processed',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              fontSize: 10,
                              height: 15 / 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.03,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _timeAgo(batch.updatedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              fontSize: 10,
                              height: 15 / 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.06,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Created ${_formatCreatedDate(batch.updatedAt)} • ${_formatCompact(total)} records',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(badgeRadius),
                  ),
                  padding: badgePadding,
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 10,
                      height: 15 / 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: badgeLetterSpacing,
                      color: badgeFg,
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

  static String _statusLabel(_BatchStatus s) => switch (s) {
    _BatchStatus.processing => 'Under Review',
    _BatchStatus.complete => 'Completed',
    _BatchStatus.alert => 'Needs Attention',
  };
}

String _formatCreatedDate(DateTime dt) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final String dd = dt.day.toString().padLeft(2, '0');
  return '$dd ${months[dt.month - 1]}';
}

String _formatCompact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
  return value.toString();
}

String _truncateBatchId(String id, {int keep = 14}) {
  final String s = id.trim();
  if (s.length <= keep) return s;
  return '${s.substring(0, keep)}...';
}

String _timeAgo(DateTime dt) {
  final DateTime now = DateTime.now();
  Duration diff = now.difference(dt);
  if (diff.isNegative) diff = Duration.zero;

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  final int weeks = (diff.inDays / 7).floor();
  if (weeks < 4) return '${weeks}w ago';
  final int months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo ago';
  final int years = (diff.inDays / 365).floor();
  return '${years}y ago';
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

  static _DashboardSummary fromVerification(
    VerificationListResponse? data, {
    Map<String, String> savedBatchNames = const <String, String>{},
  }) {
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
      if (agg.batchName.trim().isEmpty && u.batchName.trim().isNotEmpty) {
        agg.batchName = u.batchName.trim();
      }

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

    for (final _BatchAgg agg in recent) {
      if (agg.batchName.trim().isNotEmpty) continue;
      final String? stored = savedBatchNames[agg.batchId];
      if (stored != null && stored.trim().isNotEmpty) {
        agg.batchName = stored.trim();
      }
    }

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
  String batchName = '';
  int count = 0;
  int pendingCount = 0;
  int verifiedCount = 0;
  int failedCount = 0;
  String? updatedAt;
}

enum _BatchStatus { complete, processing, alert }

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
      title: agg.batchName.trim().isNotEmpty
          ? agg.batchName.trim()
          : 'Batch $shortId',
      recordCount: agg.count,
      verifiedCount: agg.verifiedCount,
      progressFraction: progress,
      status: status,
      updatedAt:
          _DashboardSummary._tryParseIso(agg.updatedAt) ?? DateTime.now(),
      isHumanVerification: false,
    );
  }
}
