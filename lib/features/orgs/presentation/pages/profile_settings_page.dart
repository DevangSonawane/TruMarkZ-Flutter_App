import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  bool _twoFaEnabled = true;

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final profile = authAsync.value?.userProfile;
    final String displayName =
        profile?.fullName?.trim().isNotEmpty == true
            ? profile!.fullName!.trim()
            : (profile?.organizationName?.trim().isNotEmpty == true
                ? profile!.organizationName!.trim()
                : 'User');
    final String email = profile?.email ?? '';
    final bool isVerified = profile?.isVerified == true;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            titleSpacing: 8,
            leading: IconButton(
              onPressed: () => _goBack(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.brandBlue,
            ),
            title: Text(
              'Organisation Profile',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: <Widget>[],
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x142563EB),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + bottomInset),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                _OrgProfileHeader(
                  onEdit: () {},
                  displayName: displayName,
                  email: email,
                  isVerified: isVerified,
                ),
                const SizedBox(height: 24),
                const _GeneralInfoCard(),
                const SizedBox(height: 24),
                _SecurityPrivacyCard(
                  twoFaEnabled: _twoFaEnabled,
                  onTwoFaChanged: (bool v) => setState(() => _twoFaEnabled = v),
                ),
                const SizedBox(height: 24),
                const _TeamAccessCard(),
                const SizedBox(height: 24),
                _LogoutCard(
                  onLogout: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go(AppRouter.roleSelectionPath);
                  },
                ),
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgProfileHeader extends StatelessWidget {
  const _OrgProfileHeader({
    required this.onEdit,
    required this.displayName,
    required this.email,
    required this.isVerified,
  });

  final VoidCallback onEdit;
  final String displayName;
  final String email;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandBlue, width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x142563EB),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.blueTint,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.brandBlue,
                    size: 44,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.brandBlue,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: AppTypography.display2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        if (email.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.blueTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.shield_rounded,
                size: 18,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 8),
              Text(
                isVerified ? 'Verified' : 'Pending',
                style: AppTypography.body2.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _GradientPrimaryButton(label: 'Edit Public Profile', onPressed: onEdit),
      ],
    );
  }
}

class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.brandBlue, Color(0xFF004AC6)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x332563EB),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.body1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFF6FF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'You will be returned to the login / signup screen.',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onLogout,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Log out',
                style: AppTypography.body1.copyWith(
                  color: const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecessedField extends StatelessWidget {
  const _RecessedField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D2563EB),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'General Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _RecessedField(
            label: 'Official Name',
            value: 'Global Fintech Institute Ltd.',
          ),
          const SizedBox(height: 16),
          const _RecessedField(
            label: 'Registration Number',
            value: 'GFI-99283-XLM',
          ),
          const SizedBox(height: 16),
          Row(
            children: const <Widget>[
              Expanded(
                child: _RecessedField(label: 'Industry', value: 'Fintech'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _RecessedField(
                  label: 'Status',
                  value: 'Active',
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _RecessedField(
            label: 'Head Office Address',
            value: 'One Financial Plaza, Level 42, Singapore 048619',
          ),
        ],
      ),
    );
  }
}

class _SecurityPrivacyCard extends StatelessWidget {
  const _SecurityPrivacyCard({
    required this.twoFaEnabled,
    required this.onTwoFaChanged,
  });

  final bool twoFaEnabled;
  final ValueChanged<bool> onTwoFaChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Security & Privacy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TwoFaRow(enabled: twoFaEnabled, onChanged: onTwoFaChanged),
          const SizedBox(height: 14),
          Text(
            'Recent Verification Audits',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const _AuditRow(title: 'Annual Compliance', dateLabel: 'Dec 2023'),
          const _Divider(),
          const _AuditRow(title: 'KYB Re-validation', dateLabel: 'Feb 2024'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'View Audit Log',
                style: AppTypography.body2.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoFaRow extends StatelessWidget {
  const _TwoFaRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.security_rounded, color: AppColors.brandBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '2FA Protection',
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _PillToggle(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PillToggle extends StatelessWidget {
  const _PillToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.brandBlue : const Color(0xFFE7E7F3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.title, required this.dateLabel});

  final String title;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
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

class _TeamAccessCard extends StatelessWidget {
  const _TeamAccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Team & Access',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Invite'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _MemberRow(
            name: 'Alex Rivera',
            role: 'Primary Admin',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAGajBzQateu0dyzNoFk3m0MO_UB9FYk0iK7wpT6Kc8NOFaMck60mt44SA1OdKISyjUVcK2qOugLayp3SBwgSXak-1CEWP7dV8Nq0Rgl0wx71jNYpgCHG3m13OjRbEXC-gxSc-hHj51Ueyk2JMhmg9DXa2Yu6seNXksubfZ5rxaWzOPM-sPwSmj4dWrZtBJ0zBIcK2e_i8JRYxJXbmPkKdX-JzleBAxnjX-4zc6l53PGx2F7vPyqjsQCHBvRJJiCpxNbdI1nYnZvHs',
            trailing: Icons.settings_rounded,
          ),
          const SizedBox(height: 16),
          const _MemberRow(
            name: 'Sarah Chen',
            role: 'Security Officer',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDtdMN9MsOhk87qSbN4_BHmKnH59sBQcUVNA26wCF1dnAhZGAS9kFZbschHKxeiJVQ3KYMBLJgTchfMi0rcR9iHi_57_nASiZP40okC0TYntOk0Y64X-5Md3QqRRcK7Yd7vdMSIUaOxbq8DXCKzXs3hJMsjKSAtWlG3FxCIxhmeHXpKsT57KzC-mKJwet1Gimg-8i_3hXnJMV2zgnAS91nOvNBM9ZUtVFVOiGsdd7MXtSgM8hq_yRacs4te8T9dCDDHMtPgxWogYFQ',
            trailing: Icons.settings_rounded,
          ),
          const SizedBox(height: 16),
          const _MemberRow(
            name: 'Marcus Knight',
            role: 'Pending 2FA',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBav4Nqs3TTjHptGCGu7Kf_Pz2XNWBNQ2JDz8-ZYFBQkDHFh39702CocSq8GjmPyl3BCl2EAerqTWZMHqLF8HlBYMVNoDOnVVUQtmpIFczN9BKWu209YTspn_auFaiag1cT0aNfzRASaJ2MplgShzw-bAsGPOaAVUx1afvC-hBLPfvgHI_8vTW8-LtM6m9BoaU5Mk7pdFoSZCTOGP-jcMs714VnmouSpAL1Pd5Un3knEbxgeYThcgPtpgFafaFx5CDoo5FU_fLiwqg',
            grayscale: true,
            opacity: 0.6,
            nameMuted: true,
            roleIcon: Icons.pending_rounded,
            roleIconColor: AppColors.warning,
            roleColor: AppColors.warning,
            trailing: Icons.mail_rounded,
            trailingColor: Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.trailing,
    this.trailingColor,
    this.roleIcon,
    this.roleIconColor,
    this.roleColor,
    this.grayscale = false,
    this.opacity = 1,
    this.nameMuted = false,
  });

  final String name;
  final String role;
  final String imageUrl;
  final IconData trailing;
  final Color? trailingColor;
  final IconData? roleIcon;
  final Color? roleIconColor;
  final Color? roleColor;
  final bool grayscale;
  final double opacity;
  final bool nameMuted;

  static const List<double> _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.blueTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: AppColors.brandBlue),
    );
    if (grayscale) {
      avatar = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: avatar,
      );
    }

    return Row(
      children: <Widget>[
        Opacity(opacity: opacity, child: avatar),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: nameMuted
                      ? AppColors.textPrimary.withValues(alpha: 0.60)
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              if (roleIcon != null)
                Row(
                  children: <Widget>[
                    Icon(roleIcon, size: 14, color: roleIconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: roleColor ?? AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        Icon(trailing, color: trailingColor ?? AppColors.textTertiary),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF8FAFC));
  }
}
