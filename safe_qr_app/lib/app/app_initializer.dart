import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
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
  }
}
