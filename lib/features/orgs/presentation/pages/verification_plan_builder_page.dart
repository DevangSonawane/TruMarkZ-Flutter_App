import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class VerificationPlanBuilderPage extends StatelessWidget {
  const VerificationPlanBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 24),
            const SizedBox(width: AppSpacing.x2),
            const Text('Verification Plan Builder'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Build a plan', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Define steps, documents, and checks for a verification flow.',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x4),
          const TMZCard(
            child: ListTile(
              leading: Icon(
                Icons.rule_folder_rounded,
                color: AppColors.brandBlue,
              ),
              title: Text('Document checks'),
              subtitle: Text('ID, selfie, proof-of-address'),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.gavel_rounded, color: AppColors.brandBlue),
              title: Text('Policy rules'),
              subtitle: Text('Age limits, region restrictions, compliance'),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(label: 'Save Plan', onPressed: () {}),
        ],
      ),
    );
  }
}
