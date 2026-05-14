import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final String id = (qp['id'] ?? 'r_identity_1').trim();

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
                        TMZBadge.pending(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      id.isEmpty ? 'Report' : 'Report ID: $id',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      'Report details are not available in the app yet. This screen will be wired once the report-detail API is available.',
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
}
