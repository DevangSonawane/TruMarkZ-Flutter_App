import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'theme_scope.dart';

class TrumarkzAppLoadingShell extends StatelessWidget {
  const TrumarkzAppLoadingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruMarkZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SizedBox.shrink(),
    );
  }
}

class TruMarkZApp extends StatelessWidget {
  const TruMarkZApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (BuildContext context, _) {
        return ThemeScope(
          controller: themeController,
          child: MaterialApp.router(
            title: 'TruMarkZ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            // Dark theme currently causes low-contrast UI across many screens
            // that use fixed light background colors. Keep visuals readable by
            // using the light theme for both modes.
            darkTheme: AppTheme.light,
            themeMode: themeController.themeMode,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
