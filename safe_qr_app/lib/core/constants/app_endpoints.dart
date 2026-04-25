/// Caminhos da API. A URL base completa fica no [.env] via [AppConfig.apiBaseUrl].
abstract final class AppEndpoints {
  static const String v1Root = '/v1';
  static const String health = '$v1Root/health';
  static const String qrAnalyze = '$v1Root/qr/analyze';
}
