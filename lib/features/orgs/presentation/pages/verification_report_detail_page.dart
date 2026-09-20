import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/animations/screen_entry_mixin.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class VerificationReportDetailPage extends StatelessWidget
    with ScreenEntryMixin {
  const VerificationReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String id = (qp['id'] ?? '').trim();
    final String title = (qp['title'] ?? 'Verification Report').trim();
    final String category = (qp['category'] ?? '').trim();
    final String status = (qp['status'] ?? 'Verified').trim();
    final String url = (qp['url'] ?? '').trim();
    final Uri? uri = Uri.tryParse(url);
    final bool canOpen =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('Report'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x6,
            AppSpacing.x6,
            AppSpacing.x6,
            AppSpacing.x8,
          ),
          children: <Widget>[
            entry(
              TMZCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Verification Report',
                            style: AppTypography.heading1.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      title.isEmpty ? 'Verification Report' : title,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (category.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      id.isEmpty ? 'Report' : 'Report ID: $id',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      canOpen
                          ? 'Open this report in your browser to review the uploaded verification file.'
                          : 'This report is not available as an openable link in the app.',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            entry(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TMZButton(
                    label: 'Open Report',
                    icon: Icons.open_in_new_rounded,
                    onPressed: canOpen
                        ? () => launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TMZButton(
                    label: 'Back',
                    variant: TMZButtonVariant.secondary,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              delayMs: 80,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final String normalized = status.trim().toLowerCase();
    if (normalized.contains('fail') || normalized.contains('reject')) {
      return TMZBadge.failed(label: status);
    }
    if (normalized.contains('pend')) {
      return TMZBadge.pending(label: status);
    }
    return TMZBadge.verified(label: status);
  }
}
