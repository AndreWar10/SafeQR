import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/analyze_mode.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_debug_log.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../shared/presentation/widgets/app_hero_header.dart';
import '../../../../shared/presentation/widgets/safe_qr_loading_overlay.dart';
import '../../domain/entities/qr_security_verdict.dart';
import '../view_models/qr_reader_view_model.dart';
import 'scan_result_page.dart';

/// Tempo mínimo do overlay só no modo **local** (heurística instantânea). Em **remote**, o loading dura o tempo real da API.
const Duration _kReaderAnalysisOverlayMinLocal = Duration(seconds: 3);

class QrReaderPage extends StatefulWidget {
  const QrReaderPage({super.key});

  @override
  State<QrReaderPage> createState() => _QrReaderPageState();
}

class _QrReaderPageState extends State<QrReaderPage> {
  late final MobileScannerController _camera;
  bool _scanBusy = false;
  DateTime? _cooldownUntil;

  @override
  void initState() {
    super.initState();
    _camera = MobileScannerController(autoStart: true);
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final String? code =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue?.trim();
    if (code == null || code.isEmpty) {
      return;
    }
    if (_scanBusy) {
      return;
    }
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final QrReaderViewModel vm = context.read<QrReaderViewModel>();
    final AppConfig cfg = context.read<AppConfig>();
    final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);

    AppDebugLog.reader(
      'onBarcode: len=${code.length} analyzeMode=${cfg.analyzeMode} apiBase=${cfg.apiBaseUrl}',
    );

    setState(() {
      _scanBusy = true;
    });

    rootNav.push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        settings: const RouteSettings(name: 'QrReaderAnalyzing'),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (
          BuildContext routeContext,
          Animation<double> animation, // ignore: unused_parameter
          Animation<double> secondaryAnimation, // ignore: unused_parameter
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
      ),
    );
    await WidgetsBinding.instance.endOfFrame;

    try {
      final Future<QrAnalysisResult?> analysisFuture = vm.analyzeDecoded(code);
      if (cfg.analyzeMode == AnalyzeMode.remote) {
        await analysisFuture;
      } else {
        await Future.wait(<Future<Object?>>[
          analysisFuture,
          Future<void>.delayed(_kReaderAnalysisOverlayMinLocal),
        ]);
      }
      if (!mounted) {
        return;
      }
      if (rootNav.canPop()) {
        rootNav.pop();
      }
      final QrAnalysisResult? result = await analysisFuture;
      if (!mounted) {
        return;
      }
      if (result == null) {
        if (vm.error == null) {
          AppDebugLog.readerVerbose('onBarcode: resultado null sem erro (pedido ignorado ou corrida)');
          return;
        }
        final String err = vm.error!;
        AppDebugLog.reader('onBarcode: falha exibida ao usuário: $err');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        vm.clearError();
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 2));
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => ScanResultPage(result: result, raw: code),
        ),
      );
      _cooldownUntil = DateTime.now().add(const Duration(seconds: 2));
    } finally {
      if (mounted) {
        setState(() {
          _scanBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SafeQrColorTokens t = context.safeColors;
    final ColorScheme c = Theme.of(context).colorScheme;
    final AppConfig cfg = context.read<AppConfig>();
    final bool remote = cfg.analyzeMode == AnalyzeMode.remote;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppHeroHeader(
            title: AppStrings.readerTitle,
            subtitle: remote ? AppStrings.readerHelpRemote : AppStrings.readerHelpLocal,
          ),
          const SizedBox(height: 12),
          if (!remote) ...<Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  AppStrings.readerModeLocalBanner,
                  style: GoogleFonts.plusJakartaSans(
                    color: t.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _ScannerFrame(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MobileScanner(
                  controller: _camera,
                  onDetect: _onBarcodeDetected,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
