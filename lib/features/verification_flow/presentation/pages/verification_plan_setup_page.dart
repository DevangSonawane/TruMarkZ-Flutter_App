import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class VerificationPlanSetupPage extends StatelessWidget {
  const VerificationPlanSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Verification Plan Setup'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Setup a plan', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Agree to proceed with the verification plan workflow.',
            style: AppTypography.body2.copyWith(color: scheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: AppSpacing.x4),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.policy_rounded),
              title: Text('Compliance'),
              subtitle: Text('We process only the minimum required information.'),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: 'Agree & Continue',
            onPressed: () => context.go(AppRouter.credentialTemplateSelectorPath),
          ),
        ],
      ),
    );
  }
}

