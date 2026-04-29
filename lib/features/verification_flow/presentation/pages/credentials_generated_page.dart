import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class CredentialsGeneratedPage extends StatelessWidget {
  const CredentialsGeneratedPage({super.key});

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
            const Text('Success'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.x6),
            const Icon(Icons.check_circle_rounded, size: 72, color: Colors.green),
            const SizedBox(height: AppSpacing.x4),
            Text(
              'Credentials generated',
              textAlign: TextAlign.center,
              style: AppTypography.display2,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'Batch created successfully. You can now track progress.',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: scheme.onSurface.withAlpha(160)),
            ),
            const SizedBox(height: AppSpacing.x6),
            const TMZCard(
              child: ListTile(
                leading: Icon(Icons.analytics_outlined),
                title: Text('Batch Report'),
                subtitle: Text('Created 80 credentials'),
              ),
            ),
            const Spacer(),
            TMZButton(
              label: 'View Batch Report',
              onPressed: () => context.go(AppRouter.batchTrackingDetailPath),
            ),
          ],
        ),
      ),
    );
  }
}

