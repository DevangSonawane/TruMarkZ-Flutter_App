import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_badge.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

class CredentialDetailPage extends StatelessWidget {
  const CredentialDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String name = (qp['name'] ?? 'John Doe').trim().isNotEmpty
        ? qp['name']!.trim()
        : 'John Doe';
    final String statusRaw = (qp['status'] ?? 'verified').trim();
    final bool verified = statusRaw.toLowerCase() == 'verified';

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
                    Text('Workforce ID', style: AppTypography.heading1),
                    const Spacer(),
                    TMZBadge(
                      label: verified ? 'Verified' : 'Pending',
                      backgroundColor: verified
                          ? AppColors.success
                          : const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Owner: $name\nCredential ID: TMZ-9F3A-C812\nIssued: 29/04/2026',
                  style: AppTypography.body2.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          TMZCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Fields', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.x2),
                _kv('Full Name', name),
                _kv('DOB', '1997-06-12'),
                _kv('ID Number', 'ID-298172'),
                _kv('Role', 'Driver'),
                _kv('Phone', '+91 98XXXXXX21'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          TMZCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR generator coming soon.')),
              );
            },
            child: const ListTile(
              leading: Icon(Icons.qr_code_rounded),
              title: Text('Share'),
              subtitle: Text('Generate QR for public verification'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          TMZCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('On-chain proof viewer coming soon.'),
                ),
              );
            },
            child: const ListTile(
              leading: Icon(Icons.link_rounded),
              title: Text('On-chain Proof'),
              subtitle: Text('Tx: 0x9f3a...c812'),
              trailing: Icon(Icons.open_in_new_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: 'Back',
            variant: TMZButtonVariant.secondary,
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              k,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Text(
            v,
            style: AppTypography.body2.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
