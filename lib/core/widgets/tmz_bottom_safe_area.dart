import 'package:flutter/material.dart';

/// Ensures bottom UI (nav bars / CTAs) never sits under the system navigation
/// area (Android 3-button bar, iOS home indicator), while keeping a small
/// minimum padding even on gesture-nav devices.
class TMZBottomSafeArea extends StatelessWidget {
  const TMZBottomSafeArea({
    super.key,
    required this.child,
    this.minimumBottomPadding = 8,
  });

  final Widget child;
  final double minimumBottomPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: EdgeInsets.only(bottom: minimumBottomPadding),
      child: child,
    );
  }
}
