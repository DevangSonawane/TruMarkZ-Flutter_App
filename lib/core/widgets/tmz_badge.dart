import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

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

  factory TMZBadge.valid({String label = 'VALID'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgeValidBg,
    foregroundColor: AppColors.badgeValidFg,
  );

  factory TMZBadge.expired({String label = 'EXPIRED'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgeExpiredBg,
    foregroundColor: AppColors.badgeExpiredFg,
  );

  factory TMZBadge.revoked({String label = 'REVOKED'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgeRevokedBg,
    foregroundColor: AppColors.badgeRevokedFg,
  );

  factory TMZBadge.pending({String label = 'PENDING'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgePendingBg,
    foregroundColor: AppColors.badgePendingFg,
  );

  factory TMZBadge.processing({String label = 'PROCESSING'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgePendingBg,
    foregroundColor: AppColors.badgePendingFg,
  );

  factory TMZBadge.alert({String label = 'ALERT'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgeAlertBg,
    foregroundColor: AppColors.badgeAlertFg,
  );

  factory TMZBadge.manual({String label = 'MANUAL'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgeManualBg,
    foregroundColor: AppColors.badgeManualFg,
  );

  factory TMZBadge.automatic({String label = 'AUTOMATIC'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgePendingBg,
    foregroundColor: AppColors.badgePendingFg,
  );

  factory TMZBadge.complete({String label = 'COMPLETE'}) => TMZBadge(
    label: label,
    backgroundColor: AppColors.badgeValidBg,
    foregroundColor: AppColors.badgeValidFg,
  );

  // Backwards-compatible named constructors used in older UI.
  factory TMZBadge.verified({String label = 'VERIFIED'}) =>
      TMZBadge.valid(label: label);
  factory TMZBadge.failed({String label = 'FAILED'}) =>
      TMZBadge.alert(label: label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foregroundColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
