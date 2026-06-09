/// Contrato para identidade Firebase Anonymous (UID + ID Token).
abstract class UserIdentityRepository {
  /// UID estável da instalação (Firebase Anonymous Auth).
  Future<String> getOrCreateIdUser();

  /// JWT para `Authorization: Bearer` — o back valida com Firebase Admin SDK.
  Future<String> getIdToken({bool forceRefresh = false});
}
