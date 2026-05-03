import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
    ),
  );
  runApp(const TruMarkZBootstrapApp());
}

class TruMarkZBootstrapApp extends StatefulWidget {
  const TruMarkZBootstrapApp({super.key});

  @override
  State<TruMarkZBootstrapApp> createState() => _TruMarkZBootstrapAppState();
}

class _TruMarkZBootstrapAppState extends State<TruMarkZBootstrapApp> {
  late final Future<ThemeController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = ThemeController.create();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeController>(
      future: _controllerFuture,
      builder: (BuildContext context, AsyncSnapshot<ThemeController> snapshot) {
        final ThemeController? controller = snapshot.data;
        if (controller == null) {
          return MaterialApp(
            title: 'TruMarkZ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const SizedBox.shrink(),
          );
        }
        return TruMarkZApp(themeController: controller);
      },
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
        return _ThemeScope(
          controller: themeController,
          child: MaterialApp.router(
            title: 'TruMarkZ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}

class _ThemeScope extends InheritedWidget {
  const _ThemeScope({required this.controller, required super.child});

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final _ThemeScope? scope = context
        .dependOnInheritedWidgetOfExactType<_ThemeScope>();
    assert(scope != null, 'ThemeController not found in widget tree.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(_ThemeScope oldWidget) =>
      oldWidget.controller != controller;
}

extension ThemeControllerX on BuildContext {
  ThemeController get themeController => _ThemeScope.of(this);
}
