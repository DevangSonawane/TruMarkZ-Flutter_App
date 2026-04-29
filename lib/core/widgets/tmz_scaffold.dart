import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class TMZScaffold extends StatelessWidget {
  const TMZScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

