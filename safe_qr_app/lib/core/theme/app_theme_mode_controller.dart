import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expõe [ThemeMode] (claro/escuro) e persiste a escolha.
final class AppThemeModeController extends ChangeNotifier {
  AppThemeModeController({required this.prefs, required this.persistenceKey}) {
    _readFromStorage();
  }

  final SharedPreferences prefs;
  final String persistenceKey;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void _readFromStorage() {
    final raw = prefs.getString(persistenceKey);
    if (raw == 'dark') {
      _mode = ThemeMode.dark;
    } else if (raw == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.system;
    }
  }

  Future<void> setLight() => _set(ThemeMode.light);

  Future<void> setDark() => _set(ThemeMode.dark);

  Future<void> setSystem() => _set(ThemeMode.system);

  Future<void> _set(ThemeMode m) async {
    if (_mode == m) {
      return;
    }
    _mode = m;
    final v = switch (m) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(persistenceKey, v);
    notifyListeners();
  }

  Future<void> cycle() async {
    if (_mode == ThemeMode.system) {
      await setLight();
    } else if (_mode == ThemeMode.light) {
      await setDark();
    } else {
      await setSystem();
    }
  }
}
