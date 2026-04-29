import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class BulkUploadPage extends StatelessWidget {
  const BulkUploadPage({super.key});

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
            const Text('Bulk Upload'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Upload CSV', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Upload a CSV to create a batch of credentials.',
            style: AppTypography.body2.copyWith(color: scheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: AppSpacing.x4),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.upload_file_rounded),
              title: Text('credentials.csv'),
              subtitle: Text('80 records • 6 fields'),
              trailing: Icon(Icons.check_circle_rounded, color: Colors.green),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: 'Create Batch',
            onPressed: () => context.go(AppRouter.credentialsGeneratedPath),
          ),
        ],
      ),
    );
  }
}

