import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class OrgDashboardPage extends StatelessWidget {
  const OrgDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 18,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
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
          _HeroGreetingCard(name: 'Ravi', onTapSummary: () {})
              .animate()
              .fadeIn(duration: 220.ms)
              .slideY(
                begin: 0.04,
                duration: 220.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.x4),
          const _KpiScrollCards()
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
                    onTap: () =>
                        context.push(AppRouter.verificationPlanSetupPath),
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
          _BatchTile(
            title: 'Driver Onboarding Q1',
            subtitle: '200 records',
            status: _BatchStatus.complete,
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          _BatchTile(
            title: 'Delivery Staff Batch 4',
            subtitle: '85 records',
            status: _BatchStatus.processing,
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          _BatchTile(
            title: 'Security Personnel',
            subtitle: '50 records',
            status: _BatchStatus.alert,
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
        ],
      ),
    );
  }
}

class _HeroGreetingCard extends StatelessWidget {
  const _HeroGreetingCard({required this.name, required this.onTapSummary});

  final String name;
  final VoidCallback onTapSummary;

  @override
  Widget build(BuildContext context) {
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
                    const Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: <Widget>[
                        _HeroPill(label: '1,240 Verified'),
                        _HeroPill(label: '3 Active'),
                      ],
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
  const _KpiScrollCards();

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
                  child: const _KpiStatCard(
                    label: 'Total Verified',
                    value: '1,240',
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: cardWidth,
                  child: const _KpiStatCard(
                    label: 'Active Batches',
                    value: '3',
                  ),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: cardWidth,
                  child: const _KpiStatCard(label: 'Pending', value: '12'),
                ),
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.display1.copyWith(
              fontSize: 28,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w300,
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
