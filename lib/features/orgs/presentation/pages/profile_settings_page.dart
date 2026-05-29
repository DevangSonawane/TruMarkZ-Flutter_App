import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/models/auth_models.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  bool _twoFaEnabled = true;

  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final profile = authAsync.value?.userProfile;
    final String displayName = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!.trim()
        : (profile?.organizationName?.trim().isNotEmpty == true
              ? profile!.organizationName!.trim()
              : 'User');
    final String email = profile?.email ?? '';
    final bool isVerified = profile?.isVerified == true;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double scale = (constraints.maxWidth / _referenceWidth).clamp(
              0.0,
              1.0,
            );
            double s(double v) => v * scale;

            return _FigmaScaleScope(
              scale: scale,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(s(16), s(12), s(16), s(12)),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(21),
                            fontWeight: FontWeight.w600,
                            height: 19.5 / 21,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        SvgPicture.asset(
                          'assets/icons/figma/all_batches_bell.svg',
                          width: s(24),
                          height: s(24),
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(16)),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(s(20)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          s(16),
                          s(37),
                          s(16),
                          s(24) + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _OrgProfileHeader(
                              onEdit: () {},
                              displayName: displayName,
                              email: email,
                              isVerified: isVerified,
                            ),
                            SizedBox(height: s(24)),
                            _GeneralInfoCard(profile: profile),
                            SizedBox(height: s(24)),
                            _SecurityPrivacyCard(
                              twoFaEnabled: _twoFaEnabled,
                              onTwoFaChanged: (bool v) =>
                                  setState(() => _twoFaEnabled = v),
                            ),
                            SizedBox(height: s(24)),
                            const _TeamAccessCard(),
                            SizedBox(height: s(24)),
                            _LogoutCard(
                              onLogout: () async {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.go(AppRouter.roleSelectionPath);
                                }
                              },
                            ),
                            SizedBox(height: s(24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FigmaScaleScope extends InheritedWidget {
  const _FigmaScaleScope({required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_FigmaScaleScope>();
    return scope?.scale ?? 1.0;
  }

  @override
  bool updateShouldNotify(_FigmaScaleScope oldWidget) =>
      oldWidget.scale != scale;
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
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Column(
      children: <Widget>[
        _FigmaOrgAvatar(isVerified: isVerified, scale: scale),
        SizedBox(height: s(14)),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(24),
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            color: Color(0xFF0F172A),
          ),
        ),
        if (email.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: s(6)),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.02734375,
              height: 20 / 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
        SizedBox(height: s(10)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(4)),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.brandBlue, width: 1),
          ),
          child: Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05859375,
              height: 16 / 12,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        SizedBox(height: s(24)),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: s(60),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/icons/figma/account_edit_profile_icon.svg',
                  width: s(24),
                  height: s(24),
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: s(12)),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(18),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.03515625,
                    height: 28 / 18,
                    color: Colors.white,
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

class _FigmaOrgAvatar extends StatelessWidget {
  const _FigmaOrgAvatar({required this.isVerified, required this.scale});

  final bool isVerified;
  final double scale;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final double size = s(129);
    final double borderWidth = s(4.03125);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FF),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandBlue, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/figma/org_avatar_user_outline.svg',
            width: s(62),
            height: s(62),
          ),
        ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: s(40),
              height: s(40),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/figma/org_avatar_verified_badge.svg',
                width: s(24),
                height: s(23),
              ),
            ),
          ),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(s(16)),
      child: Container(
        height: s(60),
        decoration: BoxDecoration(
          color: const Color(0x0DEF4444),
          borderRadius: BorderRadius.circular(s(16)),
          border: Border.all(color: const Color(0x33EF4444), width: 2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/figma/account_logout_icon.svg',
              width: s(24),
              height: s(24),
              colorFilter: const ColorFilter.mode(
                Color(0xFFDC2626),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: s(12)),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(18),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.03515625,
                height: 28 / 18,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final String orgName = profile?.organizationName?.trim().isNotEmpty == true
        ? profile!.organizationName!.trim()
        : (profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!.trim()
              : '—');
    final String email = profile?.email.trim().isNotEmpty == true
        ? profile!.email.trim()
        : '—';
    final String registrationNumber =
        profile?.businessRegistrationNumber?.trim().isNotEmpty == true
        ? profile!.businessRegistrationNumber!.trim()
        : '—';
    final String industry = profile?.industry?.trim().isNotEmpty == true
        ? profile!.industry!.trim()
        : '—';
    final String address = profile?.address?.trim().isNotEmpty == true
        ? profile!.address!.trim()
        : '—';
    final bool isActive = profile?.isActive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'GENERAL INFORMATION',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1833819,
                height: 17.7507286 / 12,
                color: Color(0xFF323232),
              ),
            ),
            const Spacer(),
            if (isActive)
              Container(
                padding: EdgeInsets.fromLTRB(s(10), s(4), s(10), s(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(s(4)),
                ),
                child: Text(
                  'Status: Active',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1171875,
                    height: 15 / 10,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: s(12)),
        _FigmaInfoCard(
          rows: <_InfoRow>[
            _InfoRow(label: 'Official Name', value: orgName),
            _InfoRow(label: 'Official Email', value: email),
            _InfoRow(label: 'Registration Number', value: registrationNumber),
            _InfoRow(
              label: 'Industry',
              value: industry,
              leadingSvg: 'assets/icons/figma/account_icon_industry.svg',
            ),
            _InfoRow(
              label: 'Head Office Address',
              value: address,
              leadingSvg: 'assets/icons/figma/account_icon_location.svg',
            ),
            const _InfoRow(
              label: 'Website',
              value: '—',
              leadingSvg: 'assets/icons/figma/account_icon_globe.svg',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value, this.leadingSvg});

  final String label;
  final String value;
  final String? leadingSvg;
}

class _FigmaCard extends StatelessWidget {
  const _FigmaCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FigmaInfoCard extends StatelessWidget {
  const _FigmaInfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _FigmaCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            _InfoRowTile(row: rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

class _InfoRowTile extends StatelessWidget {
  const _InfoRowTile({required this.row});

  final _InfoRow row;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    final Widget labelValue = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          row.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        Text(
          row.value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(14),
            fontWeight: FontWeight.w600,
            height: 20 / 14,
            color: Color(0xFF323232),
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
      child: Row(
        children: <Widget>[
          if (row.leadingSvg != null) ...<Widget>[
            Container(
              width: s(40),
              height: s(40),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(s(12)),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                row.leadingSvg!,
                width: s(16),
                height: s(16),
                colorFilter: const ColorFilter.mode(
                  Color(0xFF94A3B8),
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: s(16)),
          ],
          Expanded(child: labelValue),
        ],
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.iconSvg,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String iconSvg;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
      child: Row(
        children: <Widget>[
          Container(
            width: s(40),
            height: s(40),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(s(12)),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconSvg,
              width: s(16),
              height: s(16),
              colorFilter: const ColorFilter.mode(
                Color(0xFF94A3B8),
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: s(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.013671875,
                    height: 20 / 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: s(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(11),
                    fontWeight: FontWeight.w400,
                    height: 16.5 / 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[trailing!],
        ],
      ),
    );
  }
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Padding(
      padding: EdgeInsets.fromLTRB(s(16), s(14), s(16), s(14)),
      child: Row(
        children: <Widget>[
          Container(
            width: s(36),
            height: s(36),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              color: AppColors.brandBlue,
              size: s(20),
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(14),
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: s(2)),
                Text(
                  role,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz_rounded,
            size: s(24),
            color: const Color(0xFF94A3B8),
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
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'SECURITY & PRIVACY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1833819,
            height: 17.7507286 / 12,
            color: Color(0xFF323232),
          ),
        ),
        SizedBox(height: s(12)),
        _FigmaCard(
          child: Column(
            children: <Widget>[
              _SecurityRow(
                iconSvg: 'assets/icons/figma/account_icon_shield.svg',
                title: 'Two-Factor Auth',
                subtitle: 'Required for all admins',
                trailing: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: twoFaEnabled,
                    onChanged: onTwoFaChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.brandBlue,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _SecurityRow(
                iconSvg: 'assets/icons/figma/account_icon_audit_refresh.svg',
                title: 'Audit Status',
                subtitle: 'Last scanned 2 hours ago',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamAccessCard extends StatelessWidget {
  const _TeamAccessCard();

  @override
  Widget build(BuildContext context) {
    final double scale = _FigmaScaleScope.of(context);
    double s(double v) => v * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'TEAM MEMBERS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(12),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1833819,
                height: 17.7507286 / 12,
                color: Color(0xFF323232),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add_rounded, size: s(16)),
              label: Text('Invite'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                visualDensity: VisualDensity.compact,
                textStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05859375,
                  height: 16 / 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: s(12)),
        _FigmaCard(
          child: Column(
            children: <Widget>[
              const _MemberLine(
                name: 'Alex Rivera',
                role: 'Owner • Full Access',
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const _MemberLine(name: 'Sarah Chen', role: 'Admin • Operations'),
              SizedBox(height: s(10)),
              Center(
                child: Text(
                  'View all 12 members',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(height: s(10)),
            ],
          ),
        ),
      ],
    );
  }
}
