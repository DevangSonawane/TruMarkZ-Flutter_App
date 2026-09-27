import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Single tab model for the liquid-glass bottom bar.
///
/// [svgAssetPath] is kept for backwards-compat with the old org shell.
/// Prefer [icon] / [selectedIcon] (Material icons) — they render crisper
/// and don't depend on asset files. If [icon] is null the svg is used.
class OrgBottomNavBarItem {
  const OrgBottomNavBarItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.selectedIcon,
    this.svgAssetPath,
    this.fontWeight,
    this.letterSpacing,
    this.isCenterAction = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? svgAssetPath;
  final FontWeight? fontWeight;
  final double? letterSpacing;

  /// When true the item renders as the raised navy "+" create button.
  final bool isCenterAction;
}

/// Floating liquid-glass pill, icons only.
///
/// - Floating pill pinned to the bottom (not a full-width bar).
/// - `BackdropFilter` blur + translucent white + hairline border + shadow.
/// - Tight centered row: Dashboard | raised navy `+` | Profile.
/// - The `+` overflows above the pill via a `Stack` with [Clip.none],
///   so it never gets chipped.
///
/// Expects exactly 3 items: [Dashboard, Create, Profile].
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
  static const Color _navyLight = Color(0xFF2563EB);

  static const double _totalHeight = 78;
  static const double _pillHeight = 60;
  static const double _maxPillWidth = 232;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        // Bottom-anchored: small bottom gap, headroom on top for the
        // raised + button which overflows above the pill.
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxPillWidth),
            child: SizedBox(
              height: _totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // Glass pill background, docked to the bottom of the box.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _pillHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(31),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(215),
                            borderRadius: BorderRadius.circular(31),
                            border: Border.all(
                              color: Colors.white.withAlpha(220),
                              width: 1.2,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withAlpha(24),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: _navy.withAlpha(12),
                                blurRadius: 16,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Icons row on top (never clipped).
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        SizedBox(
                          width: 60,
                          height: _pillHeight,
                          child: _SideTab(
                            item: items[0],
                            selected:
                                currentIndex == 0 && !items[0].isCenterAction,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Raised + : sits higher, overflows above the pill.
                        SizedBox(
                          width: 64,
                          height: _totalHeight,
                          child: _CenterCreateButton(item: items[1]),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          height: _pillHeight,
                          child: _SideTab(
                            item: items[2],
                            selected:
                                currentIndex == 2 && !items[2].isCenterAction,
                          ),
                        ),
                      ],
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

class _SideTab extends StatelessWidget {
  const _SideTab({required this.item, required this.selected});

  final OrgBottomNavBarItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = selected
        ? (item.selectedIcon ?? item.icon)
        : item.icon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 42,
          decoration: BoxDecoration(
            color: selected ? OrgBottomNavBar._navy : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: OrgBottomNavBar._navy.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: _TabIcon(item: item, icon: icon, selected: selected, size: 23),
        ),
      ),
    );
  }
}

class _CenterCreateButton extends StatefulWidget {
  const _CenterCreateButton({required this.item});

  final OrgBottomNavBarItem item;

  @override
  State<_CenterCreateButton> createState() => _CenterCreateButtonState();
}

class _CenterCreateButtonState extends State<_CenterCreateButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _setScale(double v) {
    if (_scale == v) return;
    setState(() => _scale = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setScale(0.92),
      onTapCancel: () => _setScale(1.0),
      onTapUp: (_) => _setScale(1.0),
      onTap: widget.item.onTap,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          scale: _scale,
          // Lifted above the pill; parent Stack has Clip.none so
          // nothing gets chipped.
          child: Transform.translate(
            offset: const Offset(0, -7),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    OrgBottomNavBar._navyLight,
                    OrgBottomNavBar._navy,
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: OrgBottomNavBar._navy.withAlpha(70),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(90),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withAlpha(210),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.item,
    required this.icon,
    required this.selected,
    required this.size,
  });

  final OrgBottomNavBarItem item;
  final IconData? icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : OrgBottomNavBar._inactive;
    if (icon != null) {
      return Icon(icon, size: size, color: fg);
    }
    final String? svg = item.svgAssetPath;
    if (svg == null || svg.isEmpty) {
      return Icon(Icons.circle_outlined, size: size, color: fg);
    }
    return SvgPicture.asset(
      svg,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
    );
  }
}
