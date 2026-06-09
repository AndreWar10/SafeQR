import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_qr_app/core/identity/user_identity_repository.dart';
import 'package:safe_qr_app/core/identity/user_identity_service.dart';

class _MockUserIdentityRepository extends Mock implements UserIdentityRepository {}

void main() {
  late _MockUserIdentityRepository repository;
  late UserIdentityService service;

  setUp(() {
    repository = _MockUserIdentityRepository();
    service = UserIdentityService(repository);
  });

  test('getOrCreateIdUser delega ao repositório', () async {
    when(() => repository.getOrCreateIdUser()).thenAnswer((_) async => 'firebase_uid_test');

    final String id = await service.getOrCreateIdUser();

    expect(id, 'firebase_uid_test');
    verify(() => repository.getOrCreateIdUser()).called(1);
  });

  test('getIdToken delega ao repositório', () async {
    when(() => repository.getIdToken(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => 'jwt_test_token');

    final String token = await service.getIdToken();

    expect(token, 'jwt_test_token');
    verify(() => repository.getIdToken(forceRefresh: false)).called(1);
  });

  test('authorizationHeaders devolve Bearer com o token', () async {
    when(() => repository.getIdToken(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => 'jwt_test_token');

    final Map<String, String> headers = await service.authorizationHeaders();

    expect(headers, <String, String>{'Authorization': 'Bearer jwt_test_token'});
  });
}
