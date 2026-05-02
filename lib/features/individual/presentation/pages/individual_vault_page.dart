import 'package:flutter/material.dart';
import 'dart:ui';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class IndividualVaultPage extends StatefulWidget {
  const IndividualVaultPage({super.key});

  @override
  State<IndividualVaultPage> createState() => _IndividualVaultPageState();
}

class _IndividualVaultPageState extends State<IndividualVaultPage> {
  bool _publicVisibility = true;

  @override
  Widget build(BuildContext context) {
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
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFEEF3FF), width: 1),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E7F3),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC3C6D7)),
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.blueTint,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textTertiary.withAlpha(180),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Text(
              'Encrypted Vault',
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
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          AppSpacing.x6,
          AppSpacing.x5,
          AppSpacing.x10,
        ),
        children: <Widget>[
          _PrivacyControlCard(
            enabled: _publicVisibility,
            onChanged: (bool v) => setState(() => _publicVisibility = v),
          ),
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: <Widget>[
              Text('Select to Share', style: AppTypography.heading2),
              const Spacer(),
              Text(
                'Sharing Hub'.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          const _CredentialShareCard(
            icon: Icons.school_rounded,
            title: 'University Degree',
            subtitle: 'Verified Oct 2023',
            verified: true,
          ),
          const SizedBox(height: AppSpacing.x4),
          const _CredentialShareCard(
            icon: Icons.badge_rounded,
            title: 'Digital Passport',
            subtitle: 'Expires Dec 2028',
            verified: true,
          ),
          const SizedBox(height: AppSpacing.x8),
          const _SecurityInfoCard(),
        ],
      ),
    );
  }
}

class _PrivacyControlCard extends StatelessWidget {
  const _PrivacyControlCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF3FF)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x14),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  'Public Visibility',
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: enabled,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.brandBlue,
                inactiveTrackColor: const Color(0xFFE1E2ED),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'When enabled, verified entities can discover your public credentials. Your private keys and sensitive data remain strictly encrypted.',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialShareCard extends StatelessWidget {
  const _CredentialShareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.verified,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF3FF)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x14),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF0053DB), AppColors.brandBlue],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.brandBlue.withAlpha(60),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (verified) const _VerifiedTag(),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Container(height: 1, color: const Color(0xFFEEF3FF)),
          const SizedBox(height: AppSpacing.x4),
          Row(
            children: const <Widget>[
              Expanded(
                child: _ShareAction(
                  kind: _ShareKind.whatsapp,
                  label: 'WhatsApp',
                ),
              ),
              SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _ShareAction(kind: _ShareKind.link, label: 'Link'),
              ),
              SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _ShareAction(kind: _ShareKind.pdf, label: 'PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifiedTag extends StatelessWidget {
  const _VerifiedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.verified_rounded,
            size: 14,
            color: AppColors.brandBlue,
          ),
          const SizedBox(width: 6),
          Text(
            'VERIFIED',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShareKind { whatsapp, link, pdf }

class _ShareAction extends StatelessWidget {
  const _ShareAction({required this.kind, required this.label});

  final _ShareKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (kind) {
      _ShareKind.whatsapp => (
        const Color(0xFFE8F5E9),
        const Color(0xFF16A34A),
        Icons.chat_bubble_rounded,
      ),
      _ShareKind.link => (
        const Color(0xFFEFF6FF),
        AppColors.brandBlue,
        Icons.link_rounded,
      ),
      _ShareKind.pdf => (
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        Icons.picture_as_pdf_rounded,
      ),
    };

    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: fg),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SecurityInfoCard extends StatelessWidget {
  const _SecurityInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC3C6D7).withAlpha(77)),
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.link_rounded, color: AppColors.brandBlue),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              'Your data is end-to-end encrypted and anchored to the Dhiway blockchain. This ensures immutable proof of your identity without storing personal information on central servers.',
              style: AppTypography.body2.copyWith(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
