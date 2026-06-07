import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class IndividualShellPage extends StatelessWidget {
  const IndividualShellPage({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith(AppRouter.individualScanPath)) return 1;
    if (location.startsWith(AppRouter.individualReportsPath)) return 3;
    if (location.startsWith(AppRouter.individualSdcPath)) return 4;
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
        context.go(AppRouter.individualVerificationIndustryPath);
        return;
      case 3:
        context.go(AppRouter.individualReportsPath);
        return;
      case 4:
        context.go(AppRouter.individualSdcPath);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _indexForLocation(location);
    final double safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bool isVerificationFlow = location.startsWith(
      AppRouter.individualVerificationIndustryPath,
    ) ||
        location.startsWith(AppRouter.individualVerificationChecksPath) ||
        location.startsWith(AppRouter.individualVerificationUploadPath) ||
        location.startsWith(
          AppRouter.individualVerificationCertificatePreviewPath,
        ) ||
        location.startsWith(AppRouter.individualVerificationCostBreakdownPath) ||
        location.startsWith(AppRouter.individualVerificationCompletionPath);

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
        extendBody: true,
        body: child,
        bottomNavigationBar: isVerificationFlow
            ? null
            : _IndividualBottomNav(
                safeBottom: safeBottom,
                currentIndex: currentIndex,
                onTap: (int i) => _onTap(context, i),
              ),
      ),
    );
  }
}

class _IndividualBottomNav extends StatelessWidget {
  const _IndividualBottomNav({
    required this.safeBottom,
    required this.currentIndex,
    required this.onTap,
  });

  final double safeBottom;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71.016 + safeBottom,
      padding: EdgeInsets.only(bottom: safeBottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.07),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 402,
          height: 71.016,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 12.2712,
                top: 12.864,
                width: 68.608,
                height: 45.288,
                child: _NavItemView(
                  label: 'Dashboard',
                  svgAssetPath: 'assets/icons/figma/nav_home.svg',
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Positioned(
                left: 90.9561,
                top: 12.864,
                width: 71.0925,
                height: 45.288,
                child: _NavItemView(
                  label: 'Skill Tree',
                  iconData: Icons.device_hub_outlined,
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Positioned(
                left: 172.1252,
                top: -1.88,
                width: 60.032,
                height: 60.032,
                child: _PlusNavItemView(
                  active: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Positioned(
                left: 242.2341,
                top: 12.864,
                width: 68.7456,
                height: 45.288,
                child: _NavItemView(
                  label: 'Reports',
                  svgAssetPath: 'assets/icons/figma/qa_reports.svg',
                  active: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              Positioned(
                left: 321.0565,
                top: 12.864,
                width: 68.608,
                height: 45.288,
                child: _NavItemView(
                  label: 'SDC',
                  svgAssetPath: 'assets/icons/figma/account_icon_shield.svg',
                  active: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({
    required this.label,
    this.svgAssetPath,
    this.iconData,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String? svgAssetPath;
  final IconData? iconData;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? AppColors.brandBlue : const Color(0xFF9CA3AF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.black.withAlpha(8),
        highlightColor: Colors.black.withAlpha(4),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              iconData != null
                  ? Icon(iconData, color: fg, size: 24)
                  : SvgPicture.asset(
                      svgAssetPath!,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                    ),
              const SizedBox(height: 4.29),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  height: 16.08 / 8,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusNavItemView extends StatelessWidget {
  const _PlusNavItemView({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.brandBlue,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: active
                  ? const Color(0xFFBFD2FF)
                  : const Color(0xFFF7F9FC),
              width: 4.288,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withValues(alpha: 0.34),
                offset: const Offset(0, 4.288),
                blurRadius: 6.432,
                spreadRadius: -4.288,
              ),
              BoxShadow(
                color: AppColors.brandBlue.withValues(alpha: 0.34),
                offset: const Offset(0, 10.72),
                blurRadius: 16.08,
                spreadRadius: -3.216,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
