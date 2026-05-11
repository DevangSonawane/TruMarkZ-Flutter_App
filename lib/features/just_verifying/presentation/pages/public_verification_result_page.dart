import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class PublicVerificationResultPage extends StatelessWidget {
  const PublicVerificationResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double systemBottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('Public Verification'),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4 + systemBottomInset,
        ),
        children: <Widget>[
          Text('Result', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x3),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.verified_rounded),
              title: Text('Credential Verified'),
              subtitle: Text('This credential is valid and anchored on-chain.'),
              trailing: TMZBadge(
                label: 'Verified',
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TMZCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Proof', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Tx Hash: 0x9f3a...c812\nBlock: 19288321\nNetwork: Ethereum',
                  style: AppTypography.body2.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: 'Back to Scan',
            onPressed: () => context.go(AppRouter.qrScannerPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          TMZButton(
            label: 'Search Registry',
            variant: TMZButtonVariant.secondary,
            onPressed: () => context.go(AppRouter.appRegistryPath),
          ),
        ],
      ),
    );
  }
}
