import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class OrgShellPage extends StatelessWidget {
  const OrgShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(AppRouter.walletPath)) {
      return 1;
    }
    if (location.startsWith(AppRouter.qrScannerPath)) {
      return 2;
    }
    if (location.startsWith(AppRouter.settingsPath) ||
        location.startsWith(AppRouter.notificationsPath)) {
      return 3;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboardPath);
        return;
      case 1:
        context.go(AppRouter.walletPath);
        return;
      case 2:
        context.go(AppRouter.qrScannerPath);
        return;
      case 3:
        context.go(AppRouter.settingsPath);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.brandBlue.withAlpha(18)),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.brandBlue.withAlpha(18),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _NavIcon(
              icon: Icons.grid_view_rounded,
              selected: currentIndex == 0,
              onTap: () => _onTap(context, 0),
            ),
            _NavIcon(
              icon: Icons.verified_outlined,
              selected: currentIndex == 1,
              onTap: () => _onTap(context, 1),
            ),
            _NavIcon(
              icon: Icons.center_focus_strong_outlined,
              selected: currentIndex == 2,
              onTap: () => _onTap(context, 2),
            ),
            _NavIcon(
              icon: Icons.person_outline_rounded,
              selected: currentIndex == 3,
              onTap: () => _onTap(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected
        ? AppColors.brandBlue
        : scheme.onSurface.withAlpha(140);

    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? AppColors.brandBlue : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
