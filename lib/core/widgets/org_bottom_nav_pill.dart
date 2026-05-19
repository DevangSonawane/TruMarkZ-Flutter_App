import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class OrgBottomNavPillItem {
  const OrgBottomNavPillItem({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback onTap;
}

class OrgBottomNavPill extends StatelessWidget {
  const OrgBottomNavPill({
    super.key,
    required this.items,
    required this.currentIndex,
  }) : assert(items.length == 5, 'Expected exactly 5 nav items');

  final List<OrgBottomNavPillItem> items;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + safeBottom),
      child: Material(
        color: Colors.white,
        elevation: 18,
        shadowColor: Colors.black.withAlpha(60),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.divider.withAlpha(120), width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _OrgBottomNavPillItemView(
                    item: items[i],
                    active: i == currentIndex,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgBottomNavPillItemView extends StatelessWidget {
  const _OrgBottomNavPillItemView({required this.item, required this.active});

  final OrgBottomNavPillItem item;
  final bool active;

  static const Color _fg = Color(0xFFC1BEBE);

  @override
  Widget build(BuildContext context) {
    const double iconSize = 28;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.black.withAlpha(8),
        highlightColor: Colors.black.withAlpha(4),
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Opacity(
                opacity: active ? 1.0 : 1.0,
                child: Image.asset(
                  item.assetPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  color: _fg,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 7,
                  height: 10 / 7,
                  color: _fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
