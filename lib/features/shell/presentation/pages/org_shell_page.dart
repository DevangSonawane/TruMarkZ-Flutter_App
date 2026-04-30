import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tmz_bottom_safe_area.dart';

class OrgShellPage extends StatelessWidget {
  const OrgShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final String path = Uri.parse(location).path;
    if (path.startsWith(AppRouter.appBatchesPath)) return 1;
    if (path.startsWith(AppRouter.appRegistryPath)) return 2;
    if (path.startsWith(AppRouter.settingsPath) ||
        path.startsWith(AppRouter.notificationsPath)) {
      return 3;
    }
    return 0; // Home (Dashboard)
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboardPath);
        return;
      case 1:
        context.go(AppRouter.appBatchesPath);
        return;
      case 2:
        context.go(AppRouter.appRegistryPath);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRouter.verificationPlanSetupPath),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: TMZBottomSafeArea(
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: Colors.white.withAlpha(245),
          surfaceTintColor: Colors.white,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.brandBlue.withAlpha(18)),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.brandBlue.withAlpha(16),
                  blurRadius: 18,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Batches',
                    selected: currentIndex == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: _NavItem(
                    icon: Icons.search_rounded,
                    label: 'Registry',
                    selected: currentIndex == 2,
                    onTap: () => _onTap(context, 2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: currentIndex == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
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
