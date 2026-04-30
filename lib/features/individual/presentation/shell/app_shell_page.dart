import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/tmz_bottom_nav.dart';

class IndividualShellPage extends StatelessWidget {
  const IndividualShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(AppRouter.individualScanPath)) return 1;
    if (location.startsWith(AppRouter.individualVaultPath)) return 2;
    if (location.startsWith(AppRouter.individualProfilePath)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.individualIdentityPath);
        return;
      case 1:
        context.go(AppRouter.individualScanPath);
        return;
      case 2:
        context.go(AppRouter.individualVaultPath);
        return;
      case 3:
        context.go(AppRouter.individualProfilePath);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: TMZBottomNav(
        currentIndex: currentIndex,
        onTap: (int i) => _onTap(context, i),
        showLabels: false,
        items: const <TMZBottomNavItem>[
          TMZBottomNavItem(
            label: 'Identity',
            icon: Icons.fingerprint_outlined,
            selectedIcon: Icons.fingerprint_rounded,
          ),
          TMZBottomNavItem(
            label: 'Scan',
            icon: Icons.qr_code_scanner_outlined,
            selectedIcon: Icons.qr_code_scanner_rounded,
          ),
          TMZBottomNavItem(
            label: 'Vault',
            icon: Icons.shield_outlined,
            selectedIcon: Icons.shield_rounded,
          ),
          TMZBottomNavItem(
            label: 'Profile',
            icon: Icons.account_circle_outlined,
            selectedIcon: Icons.account_circle_rounded,
          ),
        ],
      ),
    );
  }
}
