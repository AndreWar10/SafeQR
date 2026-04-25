import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_mode_controller.dart';
import 'di/dependency_injection.dart';
import '../features/qr_generator/presentation/view_models/qr_generator_view_model.dart';
import '../features/qr_history/presentation/view_models/qr_history_view_model.dart';
import '../features/qr_scanner/presentation/view_models/qr_reader_view_model.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class SafeQrRoot extends StatelessWidget {
  const SafeQrRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AppConfig>.value(value: sl()),
        ChangeNotifierProvider<AppThemeModeController>.value(value: sl()),
        ChangeNotifierProvider<QrReaderViewModel>.value(value: sl()),
        ChangeNotifierProvider<QrGeneratorViewModel>.value(value: sl()),
        ChangeNotifierProvider<QrHistoryViewModel>.value(value: sl()),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeController>(
      builder: (BuildContext context, AppThemeModeController theme, _) {
        return MaterialApp(
          title: 'Safe QR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: const SplashPage(),
        );
      },
    );
  }
}
