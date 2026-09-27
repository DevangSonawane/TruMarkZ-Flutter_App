import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/org_top_bar.dart';
import '../../../../../core/widgets/tmz_button.dart';

class InviteCreatedSuccessPage extends StatelessWidget {
  const InviteCreatedSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String email = (qp['email'] ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: OrgTopBar(title: 'Invite Created'),
            ),
            const SizedBox(height: 21),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          'Invite created successfully',
                          style: AppTypography.display2,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          email.isEmpty
                              ? 'Ask the user to check their email for the invite link.'
                              : 'Ask the user to check their email ($email) for the invite link.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: TMZButton(
                            label: 'Go to Dashboard',
                            icon: Icons.dashboard_rounded,
                            onPressed: () =>
                                context.go(AppRouter.dashboardPath),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
