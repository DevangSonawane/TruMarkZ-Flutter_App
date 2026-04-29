import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchProgressPage extends StatelessWidget {
  const BatchProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset('assets/icons/trumarkz_shield.svg', height: 24),
            const SizedBox(width: AppSpacing.x2),
            const Text('Batch Progress'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Verification batch', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Track multi-credential verification runs.',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x4),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.timelapse_rounded, color: AppColors.brandBlue),
              title: Text('Batch #A1C3'),
              subtitle: Text('In progress • 24/80 complete'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
