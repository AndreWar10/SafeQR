import 'package:flutter/foundation.dart';

import '../../../../core/identity/user_identity_exception.dart';
import '../../../../core/config/app_build_info.dart';
import '../../../../core/logging/app_debug_log.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/app_network_exception.dart';
import '../../domain/entities/qr_security_verdict.dart';
import '../../domain/use_cases/analyze_qr_code.dart';

final class QrReaderViewModel extends ChangeNotifier {
  QrReaderViewModel({
    required AnalyzeQrCode analyze,
  }) : _analyze = analyze;

  final AnalyzeQrCode _analyze;

  bool _inFlight = false;
  String? _error;

  bool get isBusy => _inFlight;
  String? get error => _error;

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  String _mapPlatform() {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'unknown',
    };
  }

  String _clip(String s, {int max = 2000}) {
    if (s.length <= max) {
      return s;
    }
    return s.substring(0, max);
  }

  /// Analisa o conteúdo lido via API (o back persiste o histórico) e devolve o resultado, ou `null` em erro.
  Future<QrAnalysisResult?> analyzeDecoded(String content) async {
    final String c = content.trim();
    if (c.isEmpty) {
      AppDebugLog.readerVerbose('analyzeDecoded ignorado: conteúdo vazio');
      return null;
    }
    if (_inFlight) {
      AppDebugLog.reader('analyzeDecoded ignorado: pedido anterior ainda em curso (_inFlight)');
      return null;
    }
    _inFlight = true;
    _error = null;
    notifyListeners();
    AppDebugLog.reader('analyzeDecoded início len=${c.length} platform=${_mapPlatform()}');
    try {
      final QrAnalysisResult r = await _analyze(
        _clip(c),
        appVersion: AppBuildInfo.versionLabel,
        platform: _mapPlatform(),
      );
      AppDebugLog.reader('analyzeDecoded OK verdict=${r.verdict.name} safeToOpen=${r.safeToOpen}');
      return r;
    } on UserIdentityException catch (e, st) {
      AppDebugLog.reader('analyzeDecoded UserIdentityException: ${e.message}', e, st);
      _error = kDebugMode ? '${AppStrings.identityError} (${e.message})' : AppStrings.identityError;
      return null;
    } on AppHttpException catch (e, st) {
      AppDebugLog.reader(
        'analyzeDecoded AppHttpException status=${e.statusCode} msg=${e.message}',
        e,
        st,
      );
      if (e.statusCode == 408) {
        _error = AppStrings.timeoutError;
      } else if (kDebugMode) {
        _error = '${AppStrings.networkError} (${e.statusCode ?? '—'}: ${e.message})';
      } else {
        _error = AppStrings.networkError;
      }
      return null;
    } on AppNetworkException catch (e, st) {
      AppDebugLog.reader('analyzeDecoded AppNetworkException: ${e.message}', e, st);
      _error = kDebugMode ? '${AppStrings.networkError} (${e.message})' : AppStrings.networkError;
      return null;
    } on Object catch (e, st) {
      AppDebugLog.reader('analyzeDecoded erro inesperado: $e', e, st);
      _error = kDebugMode ? '${AppStrings.invalidResponse} ($e)' : AppStrings.invalidResponse;
      return null;
    } finally {
      _inFlight = false;
      notifyListeners();
    }
  }
}
