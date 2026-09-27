import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/org_bottom_nav_bar.dart';
import '../../../auth/application/auth_notifier.dart';

class OrgShellPage extends ConsumerWidget {
  const OrgShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final String path = Uri.parse(location).path;
    // Profile area: settings + wallet (credentials).
    if (path.startsWith(AppRouter.settingsPath) ||
        path.startsWith(AppRouter.walletPath)) {
      return 2;
    }
    // Everything else (dashboard, batches, registry, reports, sdc)
    // highlights Dashboard. Create (index 1) is an action, never sticky.
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboardPath);
        return;
      case 1:
        // Batch type comes from settings (organisation profile) — skip the
        // type chooser when the org already has a service type saved.
        final String serviceType =
            (ref
                    .read(authNotifierProvider)
                    .value
                    ?.userProfile
                    ?.serviceType ??
                '')
                .toString()
                .trim()
                .toLowerCase();
        if (serviceType == 'human') {
          context.push(AppRouter.verificationChecksPath);
          return;
        }
        if (serviceType == 'product') {
          context.push(AppRouter.productSectorSelectorPath);
          return;
        }
        context.push(AppRouter.batchTypeSelectionPath); // Create
        return;
      case 2:
        context.go(AppRouter.settingsPath); // Profile
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = GoRouter.of(context);
    final String location = GoRouterState.of(context).uri.toString();
    final String path = Uri.parse(location).path;
    final int currentIndex = _indexForLocation(location);

    // Always keep the bottom nav visible — including Profile (settings)
    // and Wallet — so users can switch tabs from anywhere.
    final bool allowSystemBack =
        router.canPop() || path == AppRouter.dashboardPath;

    return PopScope(
      canPop: allowSystemBack,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(AppRouter.dashboardPath);
      },
      child: Scaffold(
        // Full-bleed body so the glass pill truly floats over content
        // with no bar strip behind it. Shell pages already carry
        // bottom clearance (>= 71px nav + insets) for the pill.
        extendBody: true,
        body: child,
        bottomNavigationBar: OrgBottomNavBar(
          currentIndex: currentIndex,
          items: <OrgBottomNavBarItem>[
            OrgBottomNavBarItem(
              label: 'Dashboard',
              icon: Icons.grid_view_rounded,
              selectedIcon: Icons.grid_view_rounded,
              svgAssetPath: 'assets/icons/figma/nav_home.svg',
              onTap: () => _onTap(context, ref, 0),
            ),
            OrgBottomNavBarItem(
              label: 'Create',
              isCenterAction: true,
              onTap: () => _onTap(context, ref, 1),
            ),
            OrgBottomNavBarItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              svgAssetPath: 'assets/icons/figma/nav_account.svg',
              onTap: () => _onTap(context, ref, 2),
            ),
          ],
        ),
      ),
    );
  }
}
