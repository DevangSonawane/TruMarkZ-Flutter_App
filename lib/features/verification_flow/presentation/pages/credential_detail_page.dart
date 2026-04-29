import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class CredentialDetailPage extends StatelessWidget {
  const CredentialDetailPage({super.key});

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
            const Text('Credential Detail'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          TMZCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('National ID', style: AppTypography.heading1),
                    const Spacer(),
                    const TMZBadge(
                      label: 'Verified',
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Owner: Devang Sonawane\nWallet: 0x1234...5678\nIssued: 29/04/2026',
                  style: AppTypography.body2.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.qr_code_rounded),
              title: Text('Share'),
              subtitle: Text('Generate QR code for public verification'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

