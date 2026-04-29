import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class TMZBadge extends StatelessWidget {
  const TMZBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  factory TMZBadge.verified({String label = 'Verified'}) => TMZBadge(
        label: label,
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
      );

  factory TMZBadge.pending({String label = 'Pending'}) => TMZBadge(
        label: label,
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      );

  factory TMZBadge.failed({String label = 'Failed'}) => TMZBadge(
        label: label,
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
