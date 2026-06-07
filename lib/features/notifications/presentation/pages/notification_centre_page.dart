import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class NotificationCentrePage extends StatelessWidget {
  const NotificationCentrePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String flow =
        GoRouterState.of(context).uri.queryParameters['flow']?.toLowerCase() ??
        '';
    final String backPath = switch (flow) {
      'individual' => AppRouter.individualIdentityPath,
      'org' => AppRouter.dashboardPath,
      _ => AppRouter.dashboardPath,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(backPath);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go(backPath),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Row(
            children: <Widget>[
              Image.asset('assets/icons/headers_app_icon.png', height: 24),
              const SizedBox(width: AppSpacing.x2),
              const Text('Notification Centre'),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.x4),
          children: <Widget>[
            Text('Updates', style: AppTypography.heading1),
            const SizedBox(height: AppSpacing.x3),
            TMZCard(
              onTap: () {},
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.brandBlue,
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Credential verified',
                          style: AppTypography.heading2,
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          'Your National ID was successfully verified on-chain.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Row(
                          children: <Widget>[
                            Text(
                              'Today',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            TMZBadge.verified(),
                          ],
                        ),
                      ],
                    ),
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
