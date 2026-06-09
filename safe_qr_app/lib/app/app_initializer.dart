import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/identity/user_identity_service.dart';
import '../core/logging/app_debug_log.dart';
import '../firebase_options.dart';
import 'di/dependency_injection.dart';

/// Inicialização do app antes do [runApp]: plugins, [.env], DI e preferências.
abstract final class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await dotenv.load(fileName: 'assets/.env');
    final appConfig = AppConfig.fromEnv();
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(appConfig: appConfig, sharedPreferences: prefs);
    await _ensureAnonymousIdentity();
  }

  /// Sessão anónima antecipada — evita atraso no primeiro scan e falha cedo se Auth estiver mal configurado.
  static Future<void> _ensureAnonymousIdentity() async {
    final UserIdentityService identity = sl<UserIdentityService>();
    try {
      final String uid = await identity.getOrCreateIdUser();
      final String token = await identity.getIdToken();
      AppDebugLog.identity(
        'Bootstrap: identidade pronta uid=$uid tokenLen=${token.length}',
      );
    } catch (e, st) {
      AppDebugLog.identity(
        'Bootstrap: identidade/token falhou (scan remoto não funcionará). '
        'Confirme: (1) Anonymous Auth ativo no Console, (2) SHA-1/SHA-256 do Android no projeto Firebase, '
        '(3) internet até googleapis.com (não basta só LAN com o back).',
        e,
        st,
      );
    }
  }
}
