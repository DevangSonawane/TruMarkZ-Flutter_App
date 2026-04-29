import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TMZCard extends StatelessWidget {
  const TMZCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = Card(
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.brandBlue.withAlpha(20),
      highlightColor: AppColors.brandBlue.withAlpha(10),
      child: card,
    );
  }
}
