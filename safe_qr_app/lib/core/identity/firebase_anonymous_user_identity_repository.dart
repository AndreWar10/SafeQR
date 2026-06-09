import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../logging/app_debug_log.dart';
import 'user_identity_exception.dart';
import 'user_identity_repository.dart';

/// Identidade via [FirebaseAuth.signInAnonymously] — UID persistido pelo SDK.
final class FirebaseAnonymousUserIdentityRepository implements UserIdentityRepository {
  FirebaseAnonymousUserIdentityRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  static const Duration _tokenTimeout = Duration(seconds: 20);

  final FirebaseAuth _auth;

  @override
  Future<String> getOrCreateIdUser() async {
    final User? existing = _auth.currentUser;
    if (existing != null) {
      final String uid = existing.uid;
      if (uid.isNotEmpty) {
        AppDebugLog.identityVerbose('sessão anónima existente uid=$uid');
        return uid;
      }
    }

    try {
      AppDebugLog.identity('signInAnonymously: a iniciar sessão anónima');
      final UserCredential cred = await _auth.signInAnonymously();
      final String? uid = cred.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw UserIdentityException('Firebase Auth devolveu utilizador sem UID.');
      }
      AppDebugLog.identity('signInAnonymously OK uid=$uid');
      return uid;
    } on FirebaseAuthException catch (e, st) {
      AppDebugLog.identity('signInAnonymously falhou code=${e.code}', e, st);
      throw UserIdentityException(
        _messageForAuthCode(e.code),
        cause: e,
      );
    } on UserIdentityException {
      rethrow;
    } on Object catch (e, st) {
      AppDebugLog.identity('signInAnonymously erro inesperado: $e', e, st);
      throw UserIdentityException('Não foi possível obter identidade anónima.', cause: e);
    }
  }

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    await getOrCreateIdUser();
    final User? user = _auth.currentUser;
    if (user == null) {
      throw UserIdentityException('Sessão anónima indisponível após sign-in.');
    }

    try {
      AppDebugLog.identity(
        'getIdToken: a pedir token ao Firebase (forceRefresh=$forceRefresh, timeout=${_tokenTimeout.inSeconds}s)...',
      );
      final String? token = await user
          .getIdToken(forceRefresh)
          .timeout(
            _tokenTimeout,
            onTimeout: () => throw UserIdentityException(
              'Timeout ao obter token Firebase (${_tokenTimeout.inSeconds}s). '
              'Verifique internet e SHA-1/SHA-256 do app no Firebase Console.',
            ),
          );
      if (token == null || token.isEmpty) {
        throw UserIdentityException('Firebase Auth devolveu token vazio.');
      }
      AppDebugLog.identity('getIdToken OK len=${token.length} uid=${user.uid}');
      return token;
    } on TimeoutException catch (e, st) {
      AppDebugLog.identity('getIdToken timeout', e, st);
      throw UserIdentityException(
        'Timeout ao obter token Firebase. O aparelho precisa de alcançar os servidores Google/Firebase.',
        cause: e,
      );
    } on FirebaseAuthException catch (e, st) {
      AppDebugLog.identity('getIdToken falhou code=${e.code}', e, st);
      throw UserIdentityException(
        _messageForAuthCode(e.code),
        cause: e,
      );
    } on UserIdentityException {
      rethrow;
    } on Object catch (e, st) {
      AppDebugLog.identity('getIdToken erro inesperado: $e', e, st);
      throw UserIdentityException('Não foi possível obter token de autenticação.', cause: e);
    }
  }

  static String _messageForAuthCode(String code) {
    return switch (code) {
      'admin-restricted-operation' ||
      'operation-not-allowed' =>
        'Autenticação anónima não está ativa no Firebase Console.',
      'network-request-failed' => 'Sem ligação à internet para criar sessão anónima.',
      _ => 'Falha na autenticação anónima ($code).',
    };
  }
}
