import '../identity/user_identity_service.dart';
import 'app_network.dart';

/// Injeta `Authorization: Bearer <Firebase ID Token>` em todos os pedidos ao back.
final class AuthenticatedAppNetwork implements AppNetwork {
  AuthenticatedAppNetwork({
    required AppNetwork inner,
    required UserIdentityService identity,
  })  : _inner = inner,
        _identity = identity;

  final AppNetwork _inner;
  final UserIdentityService _identity;

  Future<Map<String, String>> _withAuth(Map<String, String>? headers) async {
    final Map<String, String> auth = await _identity.authorizationHeaders();
    if (headers == null || headers.isEmpty) {
      return auth;
    }
    return <String, String>{...auth, ...headers};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    return _inner.post(path, body: body, headers: await _withAuth(headers));
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    return _inner.get(
      path,
      headers: await _withAuth(headers),
      queryParameters: queryParameters,
    );
  }

  @override
  Future<void> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    await _inner.delete(path, headers: await _withAuth(headers));
  }
}
