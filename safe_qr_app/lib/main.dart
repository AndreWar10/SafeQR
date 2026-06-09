import 'package:flutter/material.dart';
import 'app/app_initializer.dart';
import 'app/safe_qr_root.dart';

Future<void> main() async {
  await AppInitializer.initialize();
  runApp(const SafeQrRoot());
}
