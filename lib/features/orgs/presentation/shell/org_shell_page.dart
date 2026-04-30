import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tmz_bottom_nav.dart';

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
      bottomNavigationBar: TMZBottomNav(
        currentIndex: currentIndex,
        onTap: (int i) => _onTap(context, i),
        showLabels: false,
        middleGapAfterIndex: 1,
        middleGapWidth: 72,
        items: const <TMZBottomNavItem>[
          TMZBottomNavItem(label: 'Home', icon: Icons.grid_view_rounded),
          TMZBottomNavItem(
            label: 'Batches',
            icon: Icons.stacked_bar_chart_rounded,
          ),
          TMZBottomNavItem(
            label: 'Registry',
            icon: Icons.fact_check_outlined,
          ),
          TMZBottomNavItem(
            label: 'Profile',
            icon: Icons.manage_accounts_outlined,
          ),
        ],
      ),
    );
  }
}
