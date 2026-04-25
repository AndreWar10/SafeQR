import 'package:flutter/material.dart';

/// Cores além de [ColorScheme] — resolvido com [ThemeExtension] para acesso tipado.
@immutable
class SafeQrColorTokens extends ThemeExtension<SafeQrColorTokens> {
  const SafeQrColorTokens({
    required this.brand,
    required this.danger,
    required this.success,
    required this.warning,
    required this.surfaceCard,
    required this.muted,
    required this.glowStart,
    required this.glowEnd,
  });

  final Color brand;
  final Color danger;
  final Color success;
  final Color warning;
  final Color surfaceCard;
  final Color muted;
  final Color glowStart;
  final Color glowEnd;

  @override
  SafeQrColorTokens copyWith({
    Color? brand,
    Color? danger,
    Color? success,
    Color? warning,
    Color? surfaceCard,
    Color? muted,
    Color? glowStart,
    Color? glowEnd,
  }) {
    return SafeQrColorTokens(
      brand: brand ?? this.brand,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      muted: muted ?? this.muted,
      glowStart: glowStart ?? this.glowStart,
      glowEnd: glowEnd ?? this.glowEnd,
    );
  }

  @override
  SafeQrColorTokens lerp(ThemeExtension<SafeQrColorTokens>? other, double t) {
    if (other is! SafeQrColorTokens) return this;
    return SafeQrColorTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      glowStart: Color.lerp(glowStart, other.glowStart, t)!,
      glowEnd: Color.lerp(glowEnd, other.glowEnd, t)!,
    );
  }
}

/// Paletas de referência (não aplica tema sozinha).
abstract final class AppColorPalettes {
  static const SafeQrColorTokens light = SafeQrColorTokens(
    brand: Color(0xFF0D9488), // Teal-600
    danger: Color(0xFFDC2626), // Red-600
    success: Color(0xFF16A34A), // Green-600
    warning: Color(0xFFF59E0B), // Amber-500
    surfaceCard: Color(0xFFF1F5F9), // Slate-100
    muted: Color(0xFF64748B), // Slate-500
    glowStart: Color(0xFF0EA5E9), // Sky-500
    glowEnd: Color(0xFF6366F1), // Indigo-500
  );

  static const SafeQrColorTokens dark = SafeQrColorTokens(
    brand: Color(0xFF2DD4BF), // Teal-400
    danger: Color(0xFFF87171), // Red-400
    success: Color(0xFF4ADE80), // Green-400
    warning: Color(0xFFFBBF24), // Amber-400
    surfaceCard: Color(0xFF1E293B), // Slate-800
    muted: Color(0xFF94A3B8), // Slate-400
    glowStart: Color(0xFF38BDF8), // Sky-400
    glowEnd: Color(0xFF818CF8), // Indigo-400
  );
}

extension SafeQrColorX on BuildContext {
  SafeQrColorTokens get safeColors =>
      Theme.of(this).extension<SafeQrColorTokens>() ?? AppColorPalettes.light;
}
