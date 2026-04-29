import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../identity/presentation/widgets/identity_card.dart';

class CredentialWalletPage extends StatelessWidget {
  const CredentialWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset('assets/icons/trumarkz_shield.svg', height: 24),
            const SizedBox(width: AppSpacing.x2),
            const Text('Credential Wallet'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Your credentials', style: AppTypography.heading1),
          const SizedBox(height: AppSpacing.x3),
          IdentityCard(
            fullName: 'Devang Sonawane',
            walletAddress: '0x1234567890abcdef1234567890abcdef12345678',
            verificationStatus: VerificationStatus.verified,
            credentialType: 'National ID',
            issuedAt: DateTime(2026, 4, 29),
            onTap: () => context.push(AppRouter.credentialDetailPath),
          ),
          const SizedBox(height: AppSpacing.x3),
          IdentityCard(
            fullName: 'Devang Sonawane',
            walletAddress: '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
            verificationStatus: VerificationStatus.pending,
            credentialType: 'Passport',
            issuedAt: DateTime(2026, 3, 12),
            onTap: () => context.push(AppRouter.credentialDetailPath),
          ),
        ],
      ),
    );
  }
}
