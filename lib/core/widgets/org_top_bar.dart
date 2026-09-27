import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../router/app_router.dart';

/// Unified top bar for the organisation flow.
///
/// Standard (inner-page style): `[back] Title` on [AppColors.brandBlue].
/// Bell + avatar live only on the home dashboard — inner pages stay
/// chrome-free.
///
/// - [title] is the page title (Inter 20, w600, white).
/// - Back goes to [fallbackPath] when there is nothing to pop.
/// - Set [showBack] false for root tabs if needed (defaults true so every
///   page looks identical).
/// - Set [showActions] true only to also show bell + avatar (home style).
class OrgTopBar extends StatelessWidget {
  const OrgTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.showActions = false,
    this.onBack,
    this.onBellTap,
    this.onAvatarTap,
    this.avatarAssetPath = 'assets/icons/dashbaord/profile.png',
    this.fallbackPath = AppRouter.dashboardPath,
  });

  final String title;
  final bool showBack;
  final bool showActions;
  final VoidCallback? onBack;
  final VoidCallback? onBellTap;
  final VoidCallback? onAvatarTap;
  final String avatarAssetPath;
  final String fallbackPath;

  void _defaultBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackPath);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (showBack)
          InkWell(
            onTap: () => _defaultBack(context),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                'assets/icons/figma/certificates_back.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        if (showBack) const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 19.5 / 20,
              color: Colors.white,
            ),
          ),
        ),
        if (showActions) ...<Widget>[
          const SizedBox(width: 12),
          GestureDetector(
            onTap:
                onBellTap ??
                () => context.go('${AppRouter.notificationsPath}?flow=org'),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(LucideIcons.bell, color: Colors.white, size: 23),
                  Positioned(
                    right: 1,
                    top: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onAvatarTap ?? () => context.go(AppRouter.settingsPath),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(
                LucideIcons.userRound,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
