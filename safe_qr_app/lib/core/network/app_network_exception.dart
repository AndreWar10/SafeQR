/// Falha de transporte/HTTP isolada de implementações.
sealed class AppNetworkException implements Exception {
  const AppNetworkException(this.message);
  final String message;
}

/// Erro mapeado a partir de status HTTP, timeout ou conexão.
final class AppHttpException extends AppNetworkException {
  const AppHttpException(super.message, {this.statusCode});
  final int? statusCode;
}

/// Falha inesperada (parse, tipo errado) na borda.
final class AppSerializationException extends AppNetworkException {
  const AppSerializationException(super.message);
}
