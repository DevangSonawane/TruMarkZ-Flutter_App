import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

class BatchCreatedSuccessPage extends StatelessWidget {
  const BatchCreatedSuccessPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  static String _shortId(String id) {
    final String v = id.trim();
    if (v.isEmpty) return '—';
    return v.length <= 12 ? v : '${v.substring(0, 12)}…';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String batchId = (qp['batch_id'] ?? '').trim();
    final int uploaded = _tryParseInt(qp['total_uploaded'], fallback: 0);
    final int skipped = _tryParseInt(qp['total_skipped'], fallback: 0);
    final int errors = _tryParseInt(qp['errors'], fallback: 0);
    final String batchName = (qp['batch'] ?? 'New Batch').trim();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  36,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEEF3FF),
                          width: 4,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.brandBlue.withAlpha(16),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 54,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    'Batch Created!',
                    textAlign: TextAlign.center,
                    style: AppTypography.display2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Your bulk upload was received. Verification tasks will be created shortly.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZCard(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Batch Details',
                                style: AppTypography.heading2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.folder_rounded,
                              color: AppColors.brandBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          batchName,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          'Batch ID',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _shortId(batchId),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _KeyValue(
                                k: 'Uploaded',
                                v: uploaded.toString(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Expanded(
                              child: _KeyValue(
                                k: 'Skipped',
                                v: skipped.toString(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            Expanded(
                              child: _KeyValue(
                                k: 'Errors',
                                v: errors.toString(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (skipped > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.x4),
                    _InfoBanner(
                      title: '$skipped records were skipped',
                      subtitle:
                          'Check your Excel file for missing required fields (full_name, email, phone_number).',
                      color: const Color(0xFFF59E0B),
                      bg: const Color(0xFFFFFBEB),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                  if (errors > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.x3),
                    _InfoBanner(
                      title: '$errors rows had errors',
                      subtitle:
                          'Please fix the invalid rows and upload again to include them in this batch.',
                      color: AppColors.error,
                      bg: const Color(0xFFFEF2F2),
                      icon: Icons.error_outline_rounded,
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TMZButton(
                      label: 'View Batch',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: batchId.trim().isEmpty
                          ? null
                          : () => context.go(
                              '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(batchId)}',
                            ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    TMZButton(
                      label: 'Back to Dashboard',
                      variant: TMZButtonVariant.secondary,
                      icon: Icons.dashboard_rounded,
                      onPressed: () => context.go(AppRouter.dashboardPath),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.k, required this.v});

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            k.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            v,
            style: AppTypography.heading1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
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
