import 'package:flutter/widgets.dart';

import '../core/theme/theme_controller.dart';

class ThemeScope extends InheritedWidget {
  const ThemeScope({required this.controller, required super.child, super.key});

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final ThemeScope? scope =
        context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeController not found in widget tree.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.controller != controller;
}

extension ThemeControllerX on BuildContext {
  ThemeController get themeController => ThemeScope.of(this);
}
