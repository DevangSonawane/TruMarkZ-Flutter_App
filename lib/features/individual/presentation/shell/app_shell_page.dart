import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/org_bottom_nav_bar.dart';

class IndividualShellPage extends StatelessWidget {
  const IndividualShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(AppRouter.individualProfilePath) ||
        location.startsWith(AppRouter.individualVaultPath)) {
      return 2; // Profile
    }
    // Dashboard is the home for identity / scan / reports / sdc.
    // Create (index 1) is a momentary action, never sticky.
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.individualIdentityPath);
        return;
      case 1:
        context.push(AppRouter.individualVerificationIndustryPath);
        return;
      case 2:
        context.go(AppRouter.individualProfilePath);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _indexForLocation(location);
    final bool isVerificationFlow = location.startsWith(
          AppRouter.individualVerificationIndustryPath,
        ) ||
        location.startsWith(AppRouter.individualVerificationChecksPath) ||
        location.startsWith(AppRouter.individualVerificationUploadPath) ||
        location.startsWith(
          AppRouter.individualVerificationCertificatePreviewPath,
        ) ||
        location.startsWith(AppRouter.individualVerificationCostBreakdownPath) ||
        location.startsWith(AppRouter.individualVerificationCompletionPath) ||
        location.startsWith(AppRouter.individualScanPath) ||
        location.startsWith(AppRouter.individualSkillTreeBuildPath) ||
        location.startsWith(AppRouter.individualSkillTreeDetailPath) ||
        location.startsWith(AppRouter.individualSkillTreeCompletionPath);

    return PopScope(
      canPop: GoRouter.of(context).canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          context.pop(result);
        } else {
          context.go(AppRouter.individualIdentityPath);
        }
      },
      child: Scaffold(
        // Full-bleed body so the glass pill truly floats over content
        // with no bar strip behind it. Shell pages already carry
        // bottom clearance (>= 71px nav + insets) for the pill.
        extendBody: true,
        body: child,
        bottomNavigationBar: isVerificationFlow
            ? null
            : OrgBottomNavBar(
                currentIndex: currentIndex,
                items: <OrgBottomNavBarItem>[
                  OrgBottomNavBarItem(
                    label: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                    selectedIcon: Icons.grid_view_rounded,
                    svgAssetPath: 'assets/icons/figma/nav_home.svg',
                    onTap: () => _onTap(context, 0),
                  ),
                  OrgBottomNavBarItem(
                    label: 'Create',
                    isCenterAction: true,
                    onTap: () => _onTap(context, 1),
                  ),
                  OrgBottomNavBarItem(
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    svgAssetPath: 'assets/icons/figma/nav_account.svg',
                    onTap: () => _onTap(context, 2),
                  ),
                ],
              ),
      ),
    );
  }
}
