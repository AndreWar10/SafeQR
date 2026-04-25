/// Chaves do arquivo de ambiente (não contêm valores; evita strings soltas no código).
abstract final class AppEnvKeys {
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String apiConnectTimeoutMs = 'API_CONNECT_TIMEOUT_MS';
  static const String apiReceiveTimeoutMs = 'API_RECEIVE_TIMEOUT_MS';
  static const String themePersistenceKey = 'THEME_PERSISTENCE_KEY';
  /// `local` = heurísticas no dispositivo (S1 / sem API). `remote` = [POST /v1/qr/analyze] no [API_BASE_URL].
  static const String analyzeMode = 'ANALYZE_MODE';
}
