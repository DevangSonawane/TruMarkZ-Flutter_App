import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
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
          const SizedBox(width: AppSpacing.x2),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF243B53),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Colors.white,
            ),
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
          _HeroGreetingCard(name: 'Ravi', onTapSummary: () {}),
          const SizedBox(height: AppSpacing.x4),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: const <Widget>[
                _KpiMiniCard(title: 'TOTAL VERIFIED', value: '1,240'),
                SizedBox(width: AppSpacing.x3),
                _KpiMiniCard(title: 'ACTIVE BATCHES', value: '3'),
                SizedBox(width: AppSpacing.x3),
                _KpiMiniCard(title: 'PENDING', value: '12'),
              ],
            ),
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
                icon: Icons.add_box_outlined,
                onTap: () => context.push(AppRouter.verificationPlanSetupPath),
              ),
              _QuickActionCard(
                label: 'View Credentials',
                icon: Icons.badge_outlined,
                onTap: () => context.go(AppRouter.walletPath),
              ),
              _QuickActionCard(
                label: 'Skill Tree',
                icon: Icons.account_tree_outlined,
                onTap: () => context.go(AppRouter.skillTreePath),
              ),
              _QuickActionCard(
                label: 'Registry Search',
                icon: Icons.person_search_outlined,
                onTap: () => context.go(AppRouter.appRegistryPath),
              ),
            ],
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
          ),
          const SizedBox(height: AppSpacing.x2),
          _BatchTile(
            title: 'Driver Onboarding Q1',
            subtitle: '200 records',
            status: const TMZBadge(
              label: 'COMPLETE',
              backgroundColor: Color(0xFFDFF7EA),
              foregroundColor: Color(0xFF0F9D58),
            ),
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          _BatchTile(
            title: 'Delivery Staff Batch 4',
            subtitle: '85 records',
            status: const TMZBadge(
              label: 'PROCESSING',
              backgroundColor: Color(0xFFE7F0FF),
              foregroundColor: AppColors.brandBlue,
            ),
            onTap: () => context.push(AppRouter.batchTrackingDetailPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          _BatchTile(
            title: 'Security Personnel',
            subtitle: '50 records',
            status: const TMZBadge(
              label: 'ALERT',
              backgroundColor: Color(0xFFFFE7E7),
              foregroundColor: AppColors.error,
            ),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2D6BFF), Color(0xFF0B45C8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.6),
                    radius: 1.1,
                    colors: <Color>[
                      Colors.white.withAlpha(35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x5),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Good\nmorning,\n$name 👋',
                        style: AppTypography.display2.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        "Here's your\nverification summary.",
                        style: AppTypography.body2.copyWith(
                          color: Colors.white.withAlpha(210),
                          height: 1.4,
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
                const SizedBox(width: AppSpacing.x2),
                const _HeroGraphic(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(55)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroGraphic extends StatelessWidget {
  const _HeroGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: 12,
            top: 22,
            child: Transform.rotate(
              angle: -0.2,
              child: _GlassTile(
                icon: Icons.verified_user_rounded,
                iconBackground: Colors.white.withAlpha(25),
              ),
            ),
          ),
          Positioned(
            right: 44,
            top: 42,
            child: Transform.rotate(
              angle: 0.12,
              child: _GlassTile(
                icon: Icons.shield_outlined,
                iconBackground: Colors.white.withAlpha(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.icon, required this.iconBackground});

  final IconData icon;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _KpiMiniCard extends StatelessWidget {
  const _KpiMiniCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withAlpha(140)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              letterSpacing: 1,
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.heading1.copyWith(
                fontSize: 22,
                color: AppColors.brandBlue,
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TMZCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.brandBlue, size: 20),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TMZCard(
      onTap: onTap,
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.inbox_outlined,
            color: scheme.onSurface.withAlpha(170),
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
        trailing: status,
      ),
    );
  }
}
