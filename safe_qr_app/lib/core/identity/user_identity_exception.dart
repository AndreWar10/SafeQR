/// Falha ao obter identidade anónima (rede, Firebase Auth desativado, etc.).
final class UserIdentityException implements Exception {
  UserIdentityException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'UserIdentityException: $message';
}
