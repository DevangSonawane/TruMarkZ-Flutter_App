import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';

class IndividualDashboardPage extends ConsumerWidget {
  const IndividualDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final String displayName =
        authAsync.value?.userProfile?.fullName?.trim().isNotEmpty == true
            ? authAsync.value!.userProfile!.fullName!.trim()
            : 'User';

    final double safeTop = MediaQuery.paddingOf(context).top;

    final double headerTop = safeTop;
    final double welcomeTop = safeTop + 54;
    final double drawerTop = safeTop + 111;
    final double bgTop = safeTop + 211;
    final double topSectionHeight = safeTop + 375;

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
                        left: 16,
                        right: 16,
                        top: headerTop,
                        height: 40,
                        child: _HomeHeader(
                          titleLine1: 'Personal Dashboard',
                          onAlertsTap: () =>
                              context.go(AppRouter.notificationsPath),
                          onProfileTap: () =>
                              context.go(AppRouter.individualProfilePath),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: welcomeTop,
                        child: _WelcomeMessage(
                          greeting: 'Welcome back,',
                          name: displayName,
                          subtitle: 'Your verified identity at a glance.',
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: drawerTop,
                        child: _IdentityHeroCard(
                          verificationState: _VerificationState.verified,
                          onTapVerification: () =>
                              context.go(AppRouter.individualScanPath),
                          onTapSkillTree: () =>
                              context.go(AppRouter.individualScanPath),
                          onTapReports: () =>
                              context.go(AppRouter.individualReportsPath),
                          onTapSdc: () =>
                              context.go(AppRouter.individualSdcPath),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.pageBg,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.brandBlue.withValues(alpha: 0.14),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'VERIFICATION',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          height: 17.75 / 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.18,
                          color: Color(0xFF323232),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _VerificationStatusCard(
                        onStart: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Start Verification coming soon'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: MediaQuery.viewPaddingOf(context).bottom + 112,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: ColoredBox(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.titleLine1,
    this.onAlertsTap,
    this.onProfileTap,
  });

  final String titleLine1;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                titleLine1,
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
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onAlertsTap,
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({
    required this.greeting,
    required this.name,
    required this.subtitle,
  });

  final String greeting;
  final String name;
  final String subtitle;

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
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            height: 17 / 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

enum _VerificationState { verified, notVerified, inProcess }

class _IdentityHeroCard extends StatelessWidget {
  const _IdentityHeroCard({
    this.verificationState = _VerificationState.verified,
    required this.onTapVerification,
    required this.onTapSkillTree,
    required this.onTapReports,
    required this.onTapSdc,
  });

  final _VerificationState verificationState;
  final VoidCallback onTapVerification;
  final VoidCallback onTapSkillTree;
  final VoidCallback onTapReports;
  final VoidCallback onTapSdc;

  @override
  Widget build(BuildContext context) {
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
                    value: 12,
                    indicatorColor: const Color(0xFF00DDA3),
                    trackColor: const Color(0xFF323232),
                    fraction: 0.7719299258572772,
                  ),
                ),
                Positioned(
                  left: 145.3504 + 22.1644,
                  top: 0,
                  width: 145.7084,
                  child: _MetricTile(
                    label: 'Pending',
                    value: 2,
                    indicatorColor: AppColors.warning,
                    trackColor: const Color(0xFF323232),
                    fraction: 0.32631579555143664,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ID NUMBER',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Text(
                          'TMZ-8829-4401',
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(state: verificationState),
            ],
          ),
          const SizedBox(height: 29),
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
                        label: 'Verification',
                        svgAssetPath: 'assets/icons/figma/qa_scan_qr.svg',
                        iconSize: 25.662,
                        onTap: onTapVerification,
                      ),
                    ),
                    Positioned(
                      left: 97.5524,
                      top: 0,
                      child: _QuickActionCircle(
                        label: 'Skill Tree',
                        svgAssetPath: 'assets/icons/figma/nav_batches.svg',
                        iconSize: 25.662,
                        onTap: onTapSkillTree,
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
                        label: 'SDC',
                        svgAssetPath:
                            'assets/icons/figma/account_icon_shield.svg',
                        iconSize: 25.662,
                        onTap: onTapSdc,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.state});

  final _VerificationState state;

  @override
  Widget build(BuildContext context) {
    final ({
      Color fg,
      Color bg,
      String label,
    }) config = switch (state) {
      _VerificationState.verified => (
        fg: AppColors.success,
        bg: AppColors.successBg,
        label: 'Verified',
      ),
      _VerificationState.notVerified => (
        fg: AppColors.danger,
        bg: AppColors.dangerBg,
        label: 'Not verified',
      ),
      _VerificationState.inProcess => (
        fg: AppColors.warning,
        bg: AppColors.warningBg,
        label: 'In process',
      ),
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: config.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          config.label,
          style: AppTypography.caption.copyWith(
            color: config.fg,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.indicatorColor,
    required this.trackColor,
    required this.fraction,
  });

  final String label;
  final int value;
  final Color indicatorColor;
  final Color trackColor;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF323232),
              ),
            ),
            Text(
              value.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF323232),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  const _VerificationStatusCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.brandBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Verification',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Show verification when done, or start here if you need to begin.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Not started',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onStart,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.1),
                  foregroundColor: AppColors.brandBlue,
                ),
                child: const Text('Start Verification'),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
