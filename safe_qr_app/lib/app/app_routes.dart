import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../features/qr_generator/presentation/pages/qr_generator_result_page.dart';
import '../features/qr_scanner/domain/entities/qr_security_verdict.dart';
import '../features/qr_scanner/presentation/pages/scan_result_page.dart';
import '../features/shell/presentation/pages/main_shell_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../shared/presentation/widgets/safe_qr_loading_overlay.dart';

/// Argumentos de [AppRoutes.scanResult].
final class ScanResultRouteArgs {
  const ScanResultRouteArgs({required this.result, required this.raw});

  final QrAnalysisResult result;
  final String raw;
}

/// Rotas nomeadas do app. Rotas estáticas em [routes]; com argumentos em [routeGenerator].
abstract final class AppRoutes {
  static const String splash = '/';
  static const String shell = '/shell';
  static const String scanAnalyzing = '/scan/analyzing';
  static const String scanResult = '/scan/result';
  static const String generatorResult = '/generator/result';

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    splash: (_) => const SplashPage(),
    shell: (_) => const MainShellPage(),
  };

  static Route<dynamic>? routeGenerator(RouteSettings settings) {
    switch (settings.name) {
      case scanAnalyzing:
        return _scanAnalyzingRoute(settings);
      case scanResult:
        final ScanResultRouteArgs args = settings.arguments! as ScanResultRouteArgs;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ScanResultPage(result: args.result, raw: args.raw),
        );
      case generatorResult:
        final String payload = settings.arguments! as String;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => QrGeneratorResultPage(payload: payload),
        );
      default:
        return null;
    }
  }

  static PageRouteBuilder<void> _scanAnalyzingRoute(RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      opaque: true,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: const Color(0xE6000000),
            body: const Center(
              child: SafeQrLoadingOverlay(
                title: AppStrings.readerLoadingTitle,
                subtitle: AppStrings.readerLoadingSubtitle,
                leadingIcon: Icons.qr_code_scanner_rounded,
              ),
            ),
          ),
        );
      },
    );
  }
}
