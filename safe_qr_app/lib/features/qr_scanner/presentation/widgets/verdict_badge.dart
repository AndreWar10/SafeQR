import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../domain/entities/qr_security_verdict.dart';
import '../utils/verdict_presentation.dart';

class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict});
  final QrSecurityVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final bg = switch (verdict) {
      QrSecurityVerdict.safe => t.success,
      QrSecurityVerdict.suspicious => t.warning,
      QrSecurityVerdict.unsafe => t.danger,
      QrSecurityVerdict.unknown => t.muted,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          verdictToLabel(verdict).toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: bg,
          ),
        ),
      ),
    );
  }
}
