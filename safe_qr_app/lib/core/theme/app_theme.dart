import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color_tokens.dart';

/// Construção de [ThemeData] claro/escuro a partir de tokens controlados.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColorPalettes.light.brand,
      brightness: Brightness.light,
    );
    return _build(
      colorScheme: colorScheme,
      tokens: AppColorPalettes.light,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColorPalettes.dark.brand,
      brightness: Brightness.dark,
    );
    return _build(
      colorScheme: colorScheme,
      tokens: AppColorPalettes.dark,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required SafeQrColorTokens tokens,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
      extensions: <ThemeExtension<dynamic>>[tokens],
      textTheme: _textTheme(brightness).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme(brightness).titleLarge,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
      ),
    );
  }

  static TextTheme _textTheme(Brightness b) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return b == Brightness.dark
        ? base.apply(bodyColor: const Color(0xFFE2E8F0), displayColor: const Color(0xFFE2E8F0))
        : base.apply(bodyColor: const Color(0xFF0F172A), displayColor: const Color(0xFF0F172A));
  }
}
