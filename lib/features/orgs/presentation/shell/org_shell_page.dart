import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/org_bottom_nav_bar.dart';

class OrgShellPage extends StatelessWidget {
  const OrgShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final String path = Uri.parse(location).path;
    if (path.startsWith(AppRouter.appBatchesPath)) return 1; // View All
    if (path.startsWith(AppRouter.qrScannerPath)) return 2; // Scan
    if (path.startsWith(AppRouter.appRegistryPath)) {
      return 4; // Registry
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
        context.go(AppRouter.qrScannerPath); // Scan
        return;
      case 3:
        context.push(AppRouter.batchTypeSelectionPath); // New Batch
        return;
      case 4:
        context.go(AppRouter.appRegistryPath); // Registry
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
        bottomNavigationBar: OrgBottomNavBar(
          currentIndex: currentIndex,
          items: <OrgBottomNavBarItem>[
            OrgBottomNavBarItem(
              label: 'Home',
              svgAssetPath: 'assets/icons/figma/nav_home.svg',
              letterSpacing: 0.0156,
              onTap: () => _onTap(context, 0),
            ),
            OrgBottomNavBarItem(
              label: 'All Batches',
              svgAssetPath: 'assets/icons/figma/nav_batches.svg',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0078,
              onTap: () => _onTap(context, 1),
            ),
            OrgBottomNavBarItem(
              label: 'Scan',
              svgAssetPath: 'assets/icons/figma/nav_scan.svg',
              showLabel: false,
              onTap: () => _onTap(context, 2),
            ),
            OrgBottomNavBarItem(
              label: 'New Batch',
              svgAssetPath: 'assets/icons/figma/nav_new_batch.svg',
              letterSpacing: 0,
              onTap: () => _onTap(context, 3),
            ),
            OrgBottomNavBarItem(
              label: 'Registry',
              svgAssetPath: 'assets/icons/figma/registry.svg',
              letterSpacing: 0.0391,
              onTap: () => _onTap(context, 4),
            ),
          ],
        ),
      ),
    );
  }
}
