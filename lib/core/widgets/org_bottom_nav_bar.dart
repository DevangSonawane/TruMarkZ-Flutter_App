import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OrgBottomNavBarItem {
  const OrgBottomNavBarItem({
    required this.label,
    required this.svgAssetPath,
    required this.onTap,
    this.fontWeight,
    this.letterSpacing,
  });

  final String label;
  final String svgAssetPath;
  final VoidCallback onTap;
  final FontWeight? fontWeight;
  final double? letterSpacing;
}

class OrgBottomNavBar extends StatelessWidget {
  const OrgBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
  }) : assert(items.length == 3, 'Expected exactly 3 nav items');

  final List<OrgBottomNavBarItem> items;
  final int currentIndex;

  static const Color _inactive = Color(0xFF9CA3AF);
  static const Color _navy = Color(0xFF1B3387);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(190),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withAlpha(180),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 58,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double itemWidth =
                        constraints.maxWidth / items.length;
                    const double indicatorSize = 44;
                    final double left =
                        (itemWidth * currentIndex) +
                        ((itemWidth - indicatorSize) / 2);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                          left: left,
                          top: (68 - indicatorSize) / 2,
                          width: indicatorSize,
                          height: indicatorSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _navy,
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: _navy.withAlpha(70),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _NavIcon(
                                item: items[0],
                                selected: currentIndex == 0,
                              ),
                            ),
                            Expanded(
                              child: _PlusButton(
                                onTap: items[1].onTap,
                                selected: currentIndex == 1,
                              ),
                            ),
                            Expanded(
                              child: _NavIcon(
                                item: items[2],
                                selected: currentIndex == 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.item, required this.selected});

  final OrgBottomNavBarItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: item.onTap,
      child: Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(
              item.svgAssetPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                selected ? Colors.white : OrgBottomNavBar._inactive,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap, required this.selected});

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              Icons.add_rounded,
              size: 26,
              color: selected ? Colors.white : OrgBottomNavBar._inactive,
            ),
          ),
        ),
      ),
    );
  }
}
