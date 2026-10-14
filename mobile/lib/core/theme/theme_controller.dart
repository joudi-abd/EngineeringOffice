import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Day / night look.
///
/// Until the visitor presses the toggle the app simply follows the phone ([ThemeMode.system]), live.
/// Once they choose, that choice is remembered and wins over the phone's setting.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'ufuq-theme';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// True once the visitor has picked a look themselves.
  bool get isChosen => _mode != ThemeMode.system;

  /// Restores the saved choice, if there is one.
  Future<void> start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = _decode(prefs.getString(_prefsKey));
      if (saved != _mode) {
        _mode = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Flips to the opposite of what is on screen right now.
  ///
  /// When the flip lands on the look the phone itself is showing ([systemDark]), the stored choice is
  /// dropped and the app goes back to following the phone, so one extra press always undoes an override.
  Future<void> toggle({required bool currentlyDark, bool? systemDark}) {
    final goDark = !currentlyDark;
    if (systemDark != null && goDark == systemDark) return followSystem();
    return _set(goDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Goes back to following the phone.
  Future<void> followSystem() => _set(ThemeMode.system);

  Future<void> _set(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.system) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, mode.name);
      }
    } catch (_) {}
  }

  static ThemeMode _decode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
