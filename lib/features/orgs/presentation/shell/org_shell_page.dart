import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/org_bottom_nav_pill.dart';

class OrgShellPage extends StatelessWidget {
  const OrgShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final String path = Uri.parse(location).path;
    if (path.startsWith(AppRouter.appBatchesPath)) return 1; // View All
    if (path.startsWith(AppRouter.qrScannerPath)) return 3; // Scan QR
    if (path.startsWith(AppRouter.settingsPath) ||
        path.startsWith(AppRouter.notificationsPath)) {
      return 4; // Account
    }
    return 0; // Dashboard
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboardPath);
        return;
      case 1:
        context.go(AppRouter.appBatchesPath); // View All
        return;
      case 2:
        context.push(AppRouter.batchTypeSelectionPath); // Start Batch
        return;
      case 3:
        context.go(AppRouter.qrScannerPath); // Scan QR
        return;
      case 4:
        context.go(AppRouter.settingsPath); // Account
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    final String location = GoRouterState.of(context).uri.toString();
    final String path = Uri.parse(location).path;
    final int currentIndex = _indexForLocation(location);

    // Hide the organisation shell nav/FAB on full-screen pages.
    // Example: Create Credentials (wallet) should have its own header/back button.
    final bool showShellChrome = !path.startsWith(AppRouter.walletPath);

    if (!showShellChrome) {
      return Scaffold(body: child);
    }

    final bool allowSystemBack =
        router.canPop() || path == AppRouter.dashboardPath;

    return PopScope(
      canPop: allowSystemBack,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(AppRouter.dashboardPath);
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: OrgBottomNavPill(
          currentIndex: currentIndex,
          items: <OrgBottomNavPillItem>[
            OrgBottomNavPillItem(
              label: 'Dashboard',
              icon: Icons.space_dashboard_outlined,
              onTap: () => _onTap(context, 0),
            ),
            OrgBottomNavPillItem(
              label: 'View All',
              icon: Icons.grid_view_outlined,
              onTap: () => _onTap(context, 1),
            ),
            OrgBottomNavPillItem(
              label: 'Start Batch',
              icon: Icons.add_task_outlined,
              onTap: () => _onTap(context, 2),
            ),
            OrgBottomNavPillItem(
              label: 'Scan QR',
              icon: Icons.qr_code_scanner,
              onTap: () => _onTap(context, 3),
            ),
            OrgBottomNavPillItem(
              label: 'Account',
              icon: Icons.person_outline,
              onTap: () => _onTap(context, 4),
            ),
          ],
        ),
      ),
    );
  }
}
