import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Exporta o QR para PNG (fundo branco) para compartilhar ou salvar no aparelho.
final class QrPngBytes {
  QrPngBytes._();

  static const double defaultSize = 1024;

  static Future<Uint8List> encode(
    String data, {
    double size = defaultSize,
  }) async {
    final QrPainter painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
    );
    final ui.PictureRecorder rec = ui.PictureRecorder();
    final Canvas canvas = Canvas(rec);
    final double s = size;
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = Colors.white);
    painter.paint(canvas, Size(s, s));
    final ui.Picture picture = rec.endRecording();
    final ui.Image image = await picture.toImage(s.toInt(), s.toInt());
    picture.dispose();
    try {
      final ByteData? bd =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) {
        throw StateError('toByteData returned null');
      }
      return bd.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
