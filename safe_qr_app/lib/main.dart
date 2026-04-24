import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/di/dependency_injection.dart';
import 'app/safe_qr_root.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: 'assets/.env');
  final appConfig = AppConfig.fromEnv();
  final prefs = await SharedPreferences.getInstance();
  await configureDependencies(appConfig: appConfig, sharedPreferences: prefs);
  runApp(const SafeQrRoot());
}
