import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expõe [ThemeMode] (claro ou escuro) e persiste a escolha.
final class AppThemeModeController extends ChangeNotifier {
  AppThemeModeController({required this.prefs, required this.persistenceKey}) {
    _readFromStorage();
  }

  final SharedPreferences prefs;
  final String persistenceKey;

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  void _readFromStorage() {
    final String? raw = prefs.getString(persistenceKey);
    if (raw == 'light') {
      _mode = ThemeMode.light;
      return;
    }
    // Primeira abertura, valor antigo `system` ou desconhecido → escuro.
    _mode = ThemeMode.dark;
  }

  Future<void> setLight() => _set(ThemeMode.light);

  Future<void> setDark() => _set(ThemeMode.dark);

  Future<void> _set(ThemeMode m) async {
    if (_mode == m) {
      return;
    }
    _mode = m;
    final String v = m == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(persistenceKey, v);
    notifyListeners();
  }

  Future<void> cycle() async {
    if (_mode == ThemeMode.light) {
      await setDark();
    } else {
      await setLight();
    }
  }
}
