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
  static const double _sectionHeaderToCardGap = 12;

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
                          locationLine1: 'Kandivali, Mumbai',
                          locationLine2: 'Asynk Pvt Ltd',
                          avatarAssetPath: 'assets/icons/dashbaord/profile.png',
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
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: drawerTop,
                        child: _IdentityHeroCard(
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
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
                      const SizedBox(height: _sectionHeaderToCardGap),
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
  const _WelcomeMessage({
    required this.greeting,
    required this.name,
  });

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

class _IdentityHeroCard extends StatelessWidget {
  const _IdentityHeroCard({
    required this.onTapVerification,
    required this.onTapSkillTree,
    required this.onTapReports,
    required this.onTapSdc,
  });

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
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double availableWidth = constraints.maxWidth;
              const double figmaRowWidth = 314;
              const double figmaGap = 22.5226;
              final double scale = availableWidth < figmaRowWidth
                  ? availableWidth / figmaRowWidth
                  : 1.0;
              final double gap = figmaGap * scale;

              return Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricTile(
                      label: 'Verified',
                      value: 12,
                      indicatorColor: const Color(0xFF00DDA3),
                      trackColor: const Color(0xFF323232),
                      fraction: 0.7719299258572772,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _MetricTile(
                      label: 'Pending',
                      value: 2,
                      indicatorColor: const Color(0xFFF59E0B),
                      trackColor: const Color(0xFF323232),
                      fraction: 0.32631579555143664,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 31),
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
                        iconData: Icons.add_rounded,
                        iconSize: 25.662,
                        onTap: onTapVerification,
                      ),
                    ),
                    Positioned(
                      left: 97.5524,
                      top: 0,
                      child: _QuickActionCircle(
                        label: 'Skill Tree',
                        iconData: Icons.device_hub_outlined,
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
    const double barHeight = 6.12002;
    const double barRadius = 3.06001;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
          value.toString(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            height: 24 / 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0B0F19),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: barHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barRadius),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: trackColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: indicatorColor.withValues(alpha: 0.8),
                    ),
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
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.08),
                  foregroundColor: AppColors.brandBlue,
                ),
                child: Text(
                  'Start Verification',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
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
    this.svgAssetPath,
    this.iconData,
    required this.onTap,
    required this.iconSize,
  });

  final String label;
  final String? svgAssetPath;
  final IconData? iconData;
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
                  child: iconData != null
                      ? Icon(
                          iconData,
                          color: Colors.white,
                          size: iconSize,
                        )
                      : SvgPicture.asset(
                          svgAssetPath!,
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
