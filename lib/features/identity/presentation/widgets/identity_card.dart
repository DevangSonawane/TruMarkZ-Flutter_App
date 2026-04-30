import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

enum VerificationStatus { verified, pending, failed }

class IdentityCard extends StatelessWidget {
  const IdentityCard({
    super.key,
    required this.fullName,
    required this.walletAddress,
    required this.verificationStatus,
    required this.credentialType,
    required this.issuedAt,
    this.onTap,
  });

  final String fullName;
  final String walletAddress;
  final VerificationStatus verificationStatus;
  final String credentialType;
  final DateTime issuedAt;
  final VoidCallback? onTap;

  factory IdentityCard.loading({Key? key}) => IdentityCard(
    key: key,
    fullName: '',
    walletAddress: '',
    verificationStatus: VerificationStatus.pending,
    credentialType: '',
    issuedAt: DateTime.fromMillisecondsSinceEpoch(0),
    onTap: null,
  );

  @override
  Widget build(BuildContext context) {
    final bool isLoading = fullName.isEmpty && credentialType.isEmpty;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color onSurfaceVariant = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(170);

    final TMZBadge badge = switch (verificationStatus) {
      VerificationStatus.verified => TMZBadge.verified(),
      VerificationStatus.pending => TMZBadge.pending(),
      VerificationStatus.failed => TMZBadge.failed(),
    };

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 32,
              width: 32,
            ),
            const Spacer(),
            badge,
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          fullName,
          style: AppTypography.display2.copyWith(color: onSurface),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          credentialType,
          style: AppTypography.caption.copyWith(color: onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _truncateWallet(walletAddress),
                style: AppTypography.caption.copyWith(color: onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Text(
              _formatDate(issuedAt),
              style: AppTypography.caption.copyWith(color: onSurfaceVariant),
            ),
          ],
        ),
      ],
    );

    content = Stack(
      children: <Widget>[
        content,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );

    Widget card = TMZCard(onTap: onTap, child: content);

    if (isLoading) {
      card = Shimmer.fromColors(
        baseColor: AppColors.silverGray.withAlpha(89),
        highlightColor: Colors.white.withAlpha(230),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.silverGray.withAlpha(77)),
          ),
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(height: 32, width: 32, color: Colors.white),
              const SizedBox(height: AppSpacing.x4),
              Container(height: 22, width: 220, color: Colors.white),
              const SizedBox(height: AppSpacing.x2),
              Container(height: 12, width: 120, color: Colors.white),
              const SizedBox(height: AppSpacing.x4),
              Container(
                height: 12,
                width: double.infinity,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }

    return card
        .animate()
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.05, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }

  static String _truncateWallet(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }

  static String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
