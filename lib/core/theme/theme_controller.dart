import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs);

  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final String? raw = _prefs.getString(_themeModeKey);
    _themeMode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' || null => ThemeMode.system,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (value == _themeMode) return;
    _themeMode = value;
    await _prefs.setString(_themeModeKey, _serialize(value));
    notifyListeners();
  }

  static String _serialize(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static Future<ThemeController> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ThemeController controller = ThemeController(prefs);
    await controller.load();
    return controller;
  }
}
