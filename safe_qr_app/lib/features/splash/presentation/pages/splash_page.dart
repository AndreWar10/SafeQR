import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../shell/presentation/pages/main_shell_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement<dynamic, dynamic>(
        MaterialPageRoute<dynamic>(builder: (_) => const MainShellPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.safeColors;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[t.glowStart.withValues(alpha: 0.22), c.surface, t.glowEnd.withValues(alpha: 0.16)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: t.brand.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: c.surfaceContainerHighest,
                    child: Icon(Icons.shield_moon_rounded, size: 46, color: t.brand),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.splashTagline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: t.muted, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),
                const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
