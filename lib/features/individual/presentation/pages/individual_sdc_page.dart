import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class IndividualSdcPage extends StatelessWidget {
  const IndividualSdcPage({super.key});

  static const String _mockName = 'Rahul Kumar';
  static const String _mockRole = 'Supply Chain Manager';
  static const String _mockCompany = 'Skill India Digital';
  static const String _mockId = 'SDC-SCM-2024-567890';
  static const String _mockIssuedOn = '20 May 2024';
  static const String _mockValidTill = '19 May 2034';

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth < 402
                ? constraints.maxWidth
                : 402;
            final double scale = contentWidth / 402;
            double s(double v) => v * scale;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () =>
                                context.go(AppRouter.individualIdentityPath),
                            radius: s(22),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'SDC',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: s(21),
                                    fontWeight: FontWeight.w600,
                                    height: 19.5 / 21,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: s(2)),
                                Text(
                                  'Single Digital Certificate',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: s(12),
                                    fontWeight: FontWeight.w500,
                                    height: 17 / 12,
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: s(12),
                              vertical: s(7),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(s(999)),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Text(
                              'Mock data',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(10),
                                fontWeight: FontWeight.w700,
                                letterSpacing: s(0.35),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(18)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            s(16),
                            s(28),
                            s(16),
                            s(16 + safeTop),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _SectionHeader(
                                scale: scale,
                                title: 'Certificate Preview',
                                subtitle:
                                    'A clean SDC layout for the current user, driven by mock data for now.',
                              ),
                              SizedBox(height: s(20)),
                              _CertificateFrame(
                                scale: scale,
                                name: _mockName,
                                role: _mockRole,
                                company: _mockCompany,
                                certificateId: _mockId,
                                issuedOn: _mockIssuedOn,
                                validTill: _mockValidTill,
                              ),
                              SizedBox(height: s(18)),
                              _InsightCard(scale: scale, name: _mockName),
                              SizedBox(height: s(18)),
                              _ActionRow(
                                scale: scale,
                                onVerify: () => context.go(
                                  AppRouter.individualVerificationIndustryPath,
                                ),
                                onShare: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Share will hook into live data later.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.scale,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(22),
            fontWeight: FontWeight.w800,
            height: 26 / 22,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: s(8)),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(12),
            fontWeight: FontWeight.w400,
            height: 18 / 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CertificateFrame extends StatelessWidget {
  const _CertificateFrame({
    required this.scale,
    required this.name,
    required this.role,
    required this.company,
    required this.certificateId,
    required this.issuedOn,
    required this.validTill,
  });

  final double scale;
  final String name;
  final String role;
  final String company;
  final String certificateId;
  final String issuedOn;
  final String validTill;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(24)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.12),
            blurRadius: s(24),
            offset: Offset(0, s(10)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(s(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(s(16)),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF0B1E4A), Color(0xFF2563EB)],
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: s(42),
                    height: s(42),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(s(12)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'SDC',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(12),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Single Digital Certificate',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(18),
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: s(4)),
                        Text(
                          'Mock certificate preview for ${name.split(' ').first}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(11),
                            fontWeight: FontWeight.w500,
                            height: 16 / 11,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: s(10),
                      vertical: s(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(s(999)),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(10),
                        fontWeight: FontWeight.w700,
                        letterSpacing: s(0.5),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(s(16)),
              child: Column(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(s(18)),
                    child: AspectRatio(
                      aspectRatio: 866 / 1230,
                      child: Image.asset(
                        'assets/images/certificate_preview_sample.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: s(14)),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniStat(
                          scale: scale,
                          label: 'Name',
                          value: name,
                          icon: Icons.person_rounded,
                        ),
                      ),
                      SizedBox(width: s(10)),
                      Expanded(
                        child: _MiniStat(
                          scale: scale,
                          label: 'Role',
                          value: role,
                          icon: Icons.badge_rounded,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(10)),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _InfoPill(
                          scale: scale,
                          label: 'Issued by',
                          value: company,
                        ),
                      ),
                      SizedBox(width: s(10)),
                      Expanded(
                        child: _InfoPill(
                          scale: scale,
                          label: 'Certificate ID',
                          value: certificateId,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(10)),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _InfoPill(
                          scale: scale,
                          label: 'Issued on',
                          value: issuedOn,
                        ),
                      ),
                      SizedBox(width: s(10)),
                      Expanded(
                        child: _InfoPill(
                          scale: scale,
                          label: 'Valid till',
                          value: validTill,
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.scale, required this.name});

  final double scale;
  final String name;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final String firstName = name.split(' ').first;

    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(22)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: s(42),
            height: s(42),
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(s(14)),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.brandBlue,
              size: 24,
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Why this SDC matters',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(16),
                    fontWeight: FontWeight.w800,
                    height: 24 / 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: s(6)),
                Text(
                  '$firstName\'s certificate is structured to show identity, role, and traceability in one place.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: s(12)),
                Wrap(
                  spacing: s(8),
                  runSpacing: s(8),
                  children: <Widget>[
                    _TinyPill(scale: scale, label: 'Identity verified'),
                    _TinyPill(scale: scale, label: 'Role attached'),
                    _TinyPill(scale: scale, label: 'Ready for issuance'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.scale,
    required this.onVerify,
    required this.onShare,
  });

  final double scale;
  final VoidCallback onVerify;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: s(52),
            child: FilledButton(
              onPressed: onVerify,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.darkNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s(18)),
                ),
              ),
              child: Text(
                'Start Verification',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: s(12)),
        Expanded(
          child: SizedBox(
            height: s(52),
            child: OutlinedButton(
              onPressed: onShare,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s(18)),
                ),
              ),
              child: Text(
                'Share',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.scale,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double scale;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: s(32),
            height: s(32),
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(s(10)),
            ),
            child: Icon(icon, color: AppColors.brandBlue, size: s(18)),
          ),
          SizedBox(width: s(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: s(0.25),
                    color: AppColors.textTertiary,
                  ),
                ),
                SizedBox(height: s(4)),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(13),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.scale,
    required this.label,
    required this.value,
  });

  final double scale;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(10),
              fontWeight: FontWeight.w700,
              letterSpacing: s(0.25),
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: s(4)),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(7)),
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(s(999)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(10),
          fontWeight: FontWeight.w700,
          color: AppColors.brandBlue,
        ),
      ),
    );
  }
}
