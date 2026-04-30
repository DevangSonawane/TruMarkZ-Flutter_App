import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class TMZBottomNavItem {
  const TMZBottomNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class TMZBottomNav extends StatelessWidget {
  const TMZBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
    this.middleGapWidth,
    this.middleGapAfterIndex,
  });

  final List<TMZBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;
  final double? middleGapWidth;
  final int? middleGapAfterIndex;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + safeBottom),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < items.length; index++) ...<Widget>[
            Expanded(
              child: _NavItem(
                item: items[index],
                active: index == currentIndex,
                showLabel: showLabels,
                onTap: () => onTap(index),
              ),
            ),
            if (middleGapWidth != null &&
                middleGapAfterIndex != null &&
                index == middleGapAfterIndex)
              SizedBox(width: middleGapWidth),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.active,
    required this.showLabel,
    required this.onTap,
  });

  final TMZBottomNavItem item;
  final bool active;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconFg = active ? Colors.white : AppColors.textTertiary;
    final Color labelColor = active
        ? AppColors.brandBlue
        : AppColors.textTertiary;
    final double iconBoxHeight = showLabel ? 38 : 40;
    final double labelSpacing = showLabel ? 4 : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brandBlue.withAlpha(0x0A),
        highlightColor: AppColors.brandBlue.withAlpha(0x06),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 56,
                height: iconBoxHeight,
                decoration: BoxDecoration(
                  color: active ? AppColors.brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  active ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: 22,
                  color: iconFg,
                ),
              ),
              if (showLabel) ...<Widget>[
                SizedBox(height: labelSpacing),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: labelColor,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
