import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class OrgBottomNavPillItem {
  const OrgBottomNavPillItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 1 + safeBottom),
      child: Material(
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black.withAlpha(60),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.divider.withAlpha(120), width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    const double iconSize = 24;
    final Color fg = active ? AppColors.brandBlue : _fg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.black.withAlpha(8),
        highlightColor: Colors.black.withAlpha(4),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(item.icon, size: iconSize, color: fg),
              const SizedBox(height: 2),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 6,
                  height: 8 / 6,
                  color: fg,
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
