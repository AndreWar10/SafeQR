import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_tokens.dart';

/// Card de loading (dialog) reutilizado no gerador e no leitor de QR.
class SafeQrLoadingOverlay extends StatefulWidget {
  const SafeQrLoadingOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon = Icons.qr_code_2_rounded,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;

  @override
  State<SafeQrLoadingOverlay> createState() => _SafeQrLoadingOverlayState();
}

class _SafeQrLoadingOverlayState extends State<SafeQrLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final SafeQrColorTokens t = context.safeColors;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 296,
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.surfaceContainerHighest,
                scheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: t.brand.withValues(alpha: 0.22),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ScaleTransition(
                scale: _pulse,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.brand.withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      widget.leadingIcon,
                      size: 52,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  color: t.brand,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
