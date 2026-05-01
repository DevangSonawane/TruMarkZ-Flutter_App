import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class CredentialPreviewApprovalPage extends StatelessWidget {
  const CredentialPreviewApprovalPage({super.key});

  static const String _photoUrl =
      'https://lh3.googleusercontent.com/aida/ADBb0uhJBdF3vTRwoK3NOiP7nL3OPGX7zx5l-funeCyySeTy4MoTcHlrG4qr9G_e4YgprZedpjQeEiT3N5EJJVEmvhhYmTweTTInBuwQsTfUv5q6j0-n5iA-kwvqjDDvdbcI0TxCUy4MtZk73p07nZOb71uEoOvHsS-BRSY-Q6bJksc2U_V3o19JXBHAjKXV3UIp2-jt1uRtYNX10ZZjudf0QvXRtKyj6xnABsBNwOUd7mQhxqaUIe0BszW_FoGDvw5T39SvwJ3BS2QO1w';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String template = (qp['template'] ?? 't1').toLowerCase();
    final String templateLabel = switch (template) {
      't2' => 'Healthcare / Nurse',
      't3' => 'Education / Student',
      't4' => 'Product / Compliance',
      't5' => 'Service / Professional',
      't6' => 'Skill Tree Credential',
      _ => 'Workforce / Driver ID',
    };

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          120,
        ),
        children: <Widget>[
          _CredentialIdCard(templateLabel: templateLabel),
          const SizedBox(height: AppSpacing.x4),
          const _WaitForApprovalCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x2,
            AppSpacing.x4,
            AppSpacing.x4,
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final Map<String, String> next = Map<String, String>.from(qp);
                final String qs = next.entries
                    .map(
                      (MapEntry<String, String> e) =>
                          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
                    )
                    .join('&');
                context.push(
                  qs.isEmpty
                      ? AppRouter.credentialsApprovedPath
                      : '${AppRouter.credentialsApprovedPath}?$qs',
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                'Approve & Generate',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialIdCard extends StatelessWidget {
  const _CredentialIdCard({required this.templateLabel});

  final String templateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandBlue.withAlpha(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.x5),
          Text(
            templateLabel,
            style: AppTypography.body2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E40AF),
            ),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x6,
              AppSpacing.x4,
              AppSpacing.x6,
              AppSpacing.x4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'YOUR LOGO',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF15803D),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                Row(
                  children: <Widget>[
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.brandBlue.withAlpha(26),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          CredentialPreviewApprovalPage._photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => ColoredBox(
                                color: AppColors.blueTint,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.brandBlue.withAlpha(200),
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Ramesh Kumar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.display2.copyWith(
                              fontSize: 20,
                              height: 1.1,
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Professional Driver',
                            style: AppTypography.body2.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const _DetailItem(
                              label: 'Service No.',
                              value: 'TRN-30568',
                            ),
                            const SizedBox(height: AppSpacing.x4),
                            const _DetailItem(
                              label: 'Licence No.',
                              value: 'MH12 2018 1234567',
                            ),
                            const SizedBox(height: AppSpacing.x4),
                            const _DetailItem(
                              label: 'Verified Checks',
                              value: '6 / 6',
                            ),
                            const SizedBox(height: AppSpacing.x4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'STATUS',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF1E3A8A)
                                        .withAlpha(153),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Text(
                                    'VERIFIED',
                                    style: AppTypography.body2.copyWith(
                                      color: const Color(0xFF15803D),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withAlpha(18),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withAlpha(14),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const _QrPlaceholder(size: 88),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x6,
              vertical: AppSpacing.x4,
            ),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withAlpha(8),
              border: Border(
                top: BorderSide(color: AppColors.brandBlue.withAlpha(26)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  'TM-TRN-2026-00394',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Valid Till: ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '20 May 2026',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
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

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: const Color(0xFF1E3A8A).withAlpha(153),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body2.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WaitForApprovalCard extends StatelessWidget {
  const _WaitForApprovalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Wait for approval',
                  style: AppTypography.body1.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please review the credential preview. Once approved, we will generate credentials for the entire batch.',
                  style: AppTypography.body2.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.25,
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

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Color c = const Color(0xFF0F172A);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _QrPainter(color: c)),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    double s(double v) => v * size.width / 88.0;

    // Finder patterns (simplified).
    canvas.drawRect(Rect.fromLTWH(s(12), s(12), s(20), s(20)), p);
    canvas.drawRect(Rect.fromLTWH(s(16), s(16), s(12), s(12)), Paint()
      ..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(s(20), s(20), s(4), s(4)), p);

    canvas.drawRect(Rect.fromLTWH(s(56), s(12), s(20), s(20)), p);
    canvas.drawRect(Rect.fromLTWH(s(60), s(16), s(12), s(12)), Paint()
      ..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(s(64), s(20), s(4), s(4)), p);

    canvas.drawRect(Rect.fromLTWH(s(12), s(56), s(20), s(20)), p);
    canvas.drawRect(Rect.fromLTWH(s(16), s(60), s(12), s(12)), Paint()
      ..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(s(20), s(64), s(4), s(4)), p);

    // Some random blocks.
    canvas.drawRect(Rect.fromLTWH(s(56), s(56), s(8), s(8)), p);
    canvas.drawRect(Rect.fromLTWH(s(68), s(56), s(8), s(8)), p);
    canvas.drawRect(Rect.fromLTWH(s(60), s(64), s(8), s(8)), p);
    canvas.drawRect(Rect.fromLTWH(s(72), s(64), s(4), s(4)), p);
    canvas.drawRect(Rect.fromLTWH(s(56), s(72), s(12), s(4)), p);
    canvas.drawRect(Rect.fromLTWH(s(72), s(72), s(4), s(4)), p);
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.color != color;
}
