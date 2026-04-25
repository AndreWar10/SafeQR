import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_env_keys.dart';
import 'analyze_mode.dart';

/// Configuração carregada a partir de [assets/.env] (flutter_dotenv).
final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.themePersistenceKey,
    required this.analyzeMode,
  });

  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final String themePersistenceKey;
  final AnalyzeMode analyzeMode;

  static AppConfig fromEnv() {
    return AppConfig(
      apiBaseUrl: _readRequired(AppEnvKeys.apiBaseUrl),
      connectTimeout: _readDurationMs(AppEnvKeys.apiConnectTimeoutMs, fallbackMs: 20000),
      receiveTimeout: _readDurationMs(AppEnvKeys.apiReceiveTimeoutMs, fallbackMs: 20000),
      themePersistenceKey: dotenv.get(
        AppEnvKeys.themePersistenceKey,
        fallback: 'safe_qr_theme_mode',
      ),
      analyzeMode: _readAnalyzeMode(),
    );
  }

  static AnalyzeMode _readAnalyzeMode() {
    final v = dotenv.get(AppEnvKeys.analyzeMode, fallback: 'local').trim().toLowerCase();
    if (v == 'remote' || v == 'api' || v == 'server') {
      return AnalyzeMode.remote;
    }
    return AnalyzeMode.local;
  }

  static Duration _readDurationMs(String key, {required int fallbackMs}) {
    final raw = dotenv.get(key, fallback: '$fallbackMs');
    final v = int.tryParse(raw) ?? fallbackMs;
    return Duration(milliseconds: v);
  }

  static String _readRequired(String key) {
    final v = dotenv.get(key, fallback: '');
    if (v.isEmpty) {
      throw StateError('Missing or empty $key in .env');
    }
    return v;
  }
}
