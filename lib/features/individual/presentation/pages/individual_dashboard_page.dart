import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        titleSpacing: AppSpacing.x4,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFEEF3FF), width: 1),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: <Widget>[
            const Icon(
              Icons.shield_rounded,
              color: AppColors.brandBlue,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.x3),
            Text(
              'TruMarkZ',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.brandBlue,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.x2),
            child: InkWell(
              onTap: () => context.push(AppRouter.notificationsPath),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.x3),
            child: InkWell(
              onTap: () => context.push(AppRouter.individualProfilePath),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.blueTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          AppSpacing.x4,
          AppSpacing.x5,
          AppSpacing.x10,
        ),
        children: <Widget>[
          _IdentityHeroCard(displayName: displayName),
          const SizedBox(height: AppSpacing.x6),
          const _QuickStatsRow(),
          const SizedBox(height: AppSpacing.x6),
          Text('Primary Credential', style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.x3),
          const _PrimaryCredentialCard(),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: <Widget>[
              Text('Recent Activity', style: AppTypography.heading2),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See All',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          const _ActivityTile(
            icon: Icons.lock_open_rounded,
            iconColor: AppColors.brandBlue,
            title: 'Office Entry Granted',
            subtitle: 'Main Headquarters • 09:12 AM',
          ),
          const SizedBox(height: AppSpacing.x2),
          const _ActivityTile(
            icon: Icons.history_edu_rounded,
            iconColor: AppColors.warning,
            title: 'Document Signed',
            subtitle: 'Employment Contract • Yesterday',
          ),
        ],
      ),
    );
  }
}

class _IdentityHeroCard extends StatelessWidget {
  const _IdentityHeroCard({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0053DB), AppColors.brandBlue],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -48,
              right: -48,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'DIGITAL IDENTITY',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.white.withAlpha(204),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: AppTypography.display1.copyWith(
                                fontSize: 28,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withAlpha(80)),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TruMarkZ Verified',
                          style: AppTypography.body2.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
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
                                color: Colors.white.withAlpha(180),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TMZ-8829-4401',
                              style: AppTypography.body2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: _StatMiniCard(
            value: '12',
            label: 'Total Verified',
            valueColor: AppColors.brandBlue,
          ),
        ),
        SizedBox(width: AppSpacing.x3),
        Expanded(
          child: _StatMiniCard(
            value: '2',
            label: 'Pending',
            valueColor: AppColors.warning,
          ),
        ),
        SizedBox(width: AppSpacing.x3),
        Expanded(
          child: _StatMiniCard(
            value: '4',
            label: 'Orgs',
            valueColor: AppColors.brandBlue,
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withAlpha(90)),
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
        children: <Widget>[
          Text(
            value,
            style: AppTypography.heading1.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCredentialCard extends StatelessWidget {
  const _PrimaryCredentialCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withAlpha(70)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 80,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E7F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withAlpha(80)),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Senior Software Engineer',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Global Tech Industries, Inc.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withAlpha(18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.brandBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'AUTHENTICATED',
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.brandBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDF9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Container(height: 1, color: AppColors.divider.withAlpha(120)),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blueTint,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.corporate_fare_rounded,
                      size: 14,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Expires: Oct 2026',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(140),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(50)),
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E7F3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
