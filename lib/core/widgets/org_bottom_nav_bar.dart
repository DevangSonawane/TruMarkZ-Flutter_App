import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class OrgBottomNavBarItem {
  const OrgBottomNavBarItem({
    required this.label,
    required this.svgAssetPath,
    required this.onTap,
    this.fontWeight,
    this.letterSpacing,
    this.showLabel = true,
  });

  final String label;
  final String svgAssetPath;
  final VoidCallback onTap;
  final FontWeight? fontWeight;
  final double? letterSpacing;
  final bool showLabel;
}

class OrgBottomNavBar extends StatelessWidget {
  const OrgBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
  }) : assert(items.length == 5, 'Expected exactly 5 nav items');

  final List<OrgBottomNavBarItem> items;
  final int currentIndex;

  static const Color _inactive = Color(0xFF9CA3AF);
  static const double _barHeight = 71.016;
  static const double _blur = 12.864;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
        child: Container(
          height: _barHeight + safeBottom,
          padding: EdgeInsets.only(bottom: safeBottom),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.07),
          ),
          // Figma bar width is 402px. Use FittedBox so layout never overflows
          // on smaller devices, while keeping pixel-perfect positions inside.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 402,
              height: _barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 12.2712,
                    top: 12.864,
                    width: 68.608,
                    height: 45.288,
                    child: _NavItemView(
                      item: items[0],
                      active: currentIndex == 0,
                    ),
                  ),
                  Positioned(
                    left: 90.9561,
                    top: 12.864,
                    width: 71.0925,
                    height: 45.288,
                    child: _NavItemView(
                      item: items[1],
                      active: currentIndex == 1,
                    ),
                  ),
                  Positioned(
                    left: 172.1252,
                    top: -1.88,
                    width: 60.032,
                    height: 60.032,
                    child: _NavItemView(
                      item: items[2],
                      active: currentIndex == 2,
                    ),
                  ),
                  Positioned(
                    left: 242.2341,
                    top: 12.864,
                    width: 68.7456,
                    height: 45.288,
                    child: _NavItemView(
                      item: items[3],
                      active: currentIndex == 3,
                    ),
                  ),
                  Positioned(
                    left: 321.0565,
                    top: 12.864,
                    width: 68.608,
                    height: 45.288,
                    child: _NavItemView(
                      item: items[4],
                      active: currentIndex == 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({required this.item, required this.active});

  final OrgBottomNavBarItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.brandBlue : OrgBottomNavBar._inactive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.black.withAlpha(8),
        highlightColor: Colors.black.withAlpha(4),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: item.showLabel
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    SvgPicture.asset(
                      item.svgAssetPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 4.29),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        height: 16.08 / 8,
                        fontWeight: item.fontWeight ?? FontWeight.w600,
                        letterSpacing: item.letterSpacing,
                        color: fg,
                      ),
                    ),
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    item.svgAssetPath,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
