import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/presentation/widgets/app_rounded_action_button.dart';
import '../util/qr_png_bytes.dart';

class QrGeneratorResultPage extends StatefulWidget {
  const QrGeneratorResultPage({super.key, required this.payload});

  final String payload;

  @override
  State<QrGeneratorResultPage> createState() => _QrGeneratorResultPageState();
}

class _QrGeneratorResultPageState extends State<QrGeneratorResultPage> {
  bool _exportBusy = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.generatorResultTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: QrImageView(
                  data: widget.payload,
                  version: QrVersions.auto,
                  gapless: true,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  backgroundColor: c.surface,
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: c.onSurface,
                  ),
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: c.onSurface),
                  size: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppRoundedActionButton(
            onPressed: _exportBusy ? null : _saveToDevice,
            label: AppStrings.generatorSaveToDevice,
            leading: const Icon(Icons.save_alt, size: 18),
            filled: true,
          ),
          const SizedBox(height: 10),
          AppRoundedActionButton(
            onPressed: _exportBusy ? null : _shareNative,
            label: AppStrings.generatorShare,
            leading: const Icon(Icons.share, size: 18),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: OutlinedButton(
            onPressed: _exportBusy ? null : () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.generatorBackToForm,
              style: GoogleFonts.plusJakartaSans(
                color: c.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _withExportBusy(Future<void> Function() action) async {
    setState(() {
      _exportBusy = true;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _exportBusy = false;
        });
      }
    }
  }

  Future<void> _shareNative() {
    return _withExportBusy(() async {
      final bytes = await QrPngBytes.encode(widget.payload);
      final Directory dir = await getTemporaryDirectory();
      final String path = p.join(
        dir.path,
        'safe_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      final File f = File(path);
      await f.writeAsBytes(bytes, flush: true);
      if (!mounted) {
        return;
      }
      await Share.shareXFiles(
        <XFile>[XFile(f.path, mimeType: 'image/png')],
        text: 'QR — ${AppStrings.appName}',
      );
    });
  }

  Future<void> _saveToDevice() {
    return _withExportBusy(() async {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final has = await Gal.hasAccess();
      if (!has) {
        final bool ok = await Gal.requestAccess();
        if (!ok) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(AppStrings.generatorSaveToDeviceFailed)),
            );
          }
          return;
        }
      }
      if (!mounted) {
        return;
      }
      try {
        final bytes = await QrPngBytes.encode(widget.payload);
        if (!mounted) {
          return;
        }
        await Gal.putImageBytes(bytes, name: 'safe_qr', album: AppStrings.appName);
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.generatorSavedToDevice)),
        );
      } on GalException {
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(content: Text(AppStrings.generatorSaveToDeviceFailed)),
        );
      }
    });
  }
}
