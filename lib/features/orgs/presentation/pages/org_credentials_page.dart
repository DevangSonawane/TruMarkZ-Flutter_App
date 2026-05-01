import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OrgCredentialsPage extends StatelessWidget {
  const OrgCredentialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_CredentialCardModel> cards = <_CredentialCardModel>[
      const _CredentialCardModel(
        initials: 'GF',
        avatarBg: Color(0xFFDBEAFE), // blue-100
        avatarFg: Color(0xFF2563EB), // blue-600
        title: 'Senior Security Architect',
        org: 'Global Security Alliance',
        dateLabel: 'Issued: Oct 12, 2023',
        status: _CredentialStatus.valid,
      ),
      const _CredentialCardModel(
        initials: 'TS',
        avatarBg: Color(0xFFFEF3C7), // amber-100
        avatarFg: Color(0xFFD97706), // amber-600
        title: 'Technical Supervisor',
        org: 'Industrial Standards Corp',
        dateLabel: 'Expired: Jan 05, 2024',
        status: _CredentialStatus.expired,
      ),
      const _CredentialCardModel(
        initials: 'QA',
        avatarBg: Color(0xFFFFE4E6), // rose-100
        avatarFg: Color(0xFFE11D48), // rose-600
        title: 'Quality Assurance Lead',
        org: 'Precision Lab Group',
        dateLabel: 'Revoked: Mar 18, 2024',
        status: _CredentialStatus.revoked,
        dimmed: true,
      ),
      const _CredentialCardModel(
        initials: 'DS',
        avatarBg: Color(0xFFEDE9FE), // purple-100
        avatarFg: Color(0xFF7C3AED), // purple-600
        title: 'Data Science Professional',
        org: 'Tech Institute X',
        dateLabel: 'Issued: Nov 30, 2023',
        status: _CredentialStatus.valid,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRouter.dashboardPath);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 8,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 18,
              colorFilter: const ColorFilter.mode(
                AppColors.brandBlue,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                'Create Credentials',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x3,
          AppSpacing.x4,
          140,
        ),
        children: <Widget>[
          for (final _CredentialCardModel model in cards) ...<Widget>[
            _CredentialListCard(model: model, onTap: () {}),
            const SizedBox(height: AppSpacing.x3),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        child: SizedBox(
          height: 54,
          child: FloatingActionButton.extended(
            onPressed: () =>
                context.push(AppRouter.credentialTemplateSelectorPath),
            backgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Issue New Credential',
              style: AppTypography.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CredentialStatus { valid, expired, revoked }

class _CredentialCardModel {
  const _CredentialCardModel({
    required this.initials,
    required this.avatarBg,
    required this.avatarFg,
    required this.title,
    required this.org,
    required this.dateLabel,
    required this.status,
    this.dimmed = false,
  });

  final String initials;
  final Color avatarBg;
  final Color avatarFg;
  final String title;
  final String org;
  final String dateLabel;
  final _CredentialStatus status;
  final bool dimmed;
}

class _CredentialListCard extends StatelessWidget {
  const _CredentialListCard({required this.model, required this.onTap});

  final _CredentialCardModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (_CredentialStatusStyle statusStyle, Color qrColor) = switch (model
        .status) {
      _CredentialStatus.valid => (
          const _CredentialStatusStyle(
            label: 'VALID',
            bg: Color(0xFFECFDF3),
            fg: Color(0xFF16A34A),
            border: Color(0xFFD1FAE5),
          ),
          const Color(0xFF94A3B8),
        ),
      _CredentialStatus.expired => (
          const _CredentialStatusStyle(
            label: 'EXPIRED',
            bg: Color(0xFFFFFBEB),
            fg: Color(0xFFD97706),
            border: Color(0xFFFDE68A),
          ),
          const Color(0xFF94A3B8),
        ),
      _CredentialStatus.revoked => (
          const _CredentialStatusStyle(
            label: 'REVOKED',
            bg: Color(0xFFFFF1F2),
            fg: Color(0xFFE11D48),
            border: Color(0xFFFECACA),
          ),
          const Color(0xFFE2E8F0),
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF2563EB).withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: model.dimmed ? 0.7 : 1,
          child: Row(
            children: <Widget>[
              _AvatarWithBadge(
                initials: model.initials,
                bg: model.avatarBg,
                fg: model.avatarFg,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      model.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body1.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.org,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.dateLabel,
                      style: AppTypography.body2.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _CredentialStatusPill(style: statusStyle),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 20,
                    color: qrColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialStatusStyle {
  const _CredentialStatusStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color border;
}

class _CredentialStatusPill extends StatelessWidget {
  const _CredentialStatusPill({required this.style});

  final _CredentialStatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: style.border),
      ),
      child: Text(
        style.label,
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: style.fg,
        ),
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    required this.initials,
    required this.bg,
    required this.fg,
  });

  final String initials;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initials,
                  style: AppTypography.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFF6FF)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 14,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
