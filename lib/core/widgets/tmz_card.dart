import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TMZCardVariant { standard, credential, hero, blockchain, alert }

class TMZCard extends StatelessWidget {
  const TMZCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.variant = TMZCardVariant.standard,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final TMZCardVariant variant;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(20);

    final BoxDecoration decoration = switch (variant) {
      TMZCardVariant.standard => BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x14),
            blurRadius: 12 + elevation,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      TMZCardVariant.credential => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.deepNavy, AppColors.textPrimary],
        ),
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 18 + elevation,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      TMZCardVariant.hero => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.brandBlue, AppColors.deepNavy],
        ),
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(0x4D),
            blurRadius: 24 + elevation,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      TMZCardVariant.blockchain => BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(22),
            blurRadius: 18 + elevation,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      TMZCardVariant.alert => BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: radius,
        border: Border.all(color: AppColors.danger.withAlpha(80)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.danger.withAlpha(24),
            blurRadius: 12 + elevation,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    };

    final Widget content = Padding(padding: padding, child: child);
    final Widget surface = Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.brandBlue.withAlpha(0x0A),
        highlightColor: AppColors.brandBlue.withAlpha(0x06),
        child: content,
      ),
    );

    return Container(
      decoration: decoration,
      child: onTap == null ? content : surface,
    );
  }
}
