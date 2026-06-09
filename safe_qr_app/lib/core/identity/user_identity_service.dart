import 'user_identity_repository.dart';

/// Caso de uso: UID + token Firebase para chamadas autenticadas à API.
final class UserIdentityService {
  const UserIdentityService(this._repository);

  final UserIdentityRepository _repository;

  Future<String> getOrCreateIdUser() => _repository.getOrCreateIdUser();

  Future<String> getIdToken({bool forceRefresh = false}) =>
      _repository.getIdToken(forceRefresh: forceRefresh);

  /// Cabeçalhos `Authorization: Bearer <Firebase ID Token>` em todos os pedidos ao back.
  Future<Map<String, String>> authorizationHeaders({bool forceRefresh = false}) async {
    final String token = await getIdToken(forceRefresh: forceRefresh);
    return <String, String>{'Authorization': 'Bearer $token'};
  }
}
