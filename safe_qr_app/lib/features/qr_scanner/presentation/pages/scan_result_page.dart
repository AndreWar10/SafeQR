import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../shared/presentation/widgets/app_rounded_action_button.dart';
import '../../domain/entities/qr_security_verdict.dart';
import '../widgets/verdict_badge.dart';

class ScanResultPage extends StatelessWidget {
  const ScanResultPage({super.key, required this.result, required this.raw});
  final QrAnalysisResult result;
  final String raw;

  @override
  Widget build(BuildContext context) {
    final SafeQrColorTokens t = context.safeColors;
    final ColorScheme c = Theme.of(context).colorScheme;
    final bool isUrl = _looksLikeUrl(raw);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.resultTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          Center(child: VerdictBadge(verdict: result.verdict)),
          const SizedBox(height: 20),
          Text(
            _headlineFor(result),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              textStyle: Theme.of(context).textTheme.titleMedium,
              fontWeight: FontWeight.w700,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.readerResultHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: t.muted),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.rawContent,
            style: GoogleFonts.plusJakartaSans(
              color: t.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                raw,
                style: GoogleFonts.jetBrainsMono(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (result.reasons.isNotEmpty) ...<Widget>[
            Text(
              AppStrings.reasonsTitle,
              style: GoogleFonts.plusJakartaSans(
                color: t.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.generate(
              result.reasons.length,
              (int i) => _ReasonTile(index: i + 1, text: result.reasons[i], muted: t.muted),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: raw));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.readerResultCopyDone)),
              );
            },
            icon: const Icon(Icons.content_copy, size: 18),
            label: Text(AppStrings.copy, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          if (isUrl)
            AppRoundedActionButton(
              onPressed: () => _openIfPossible(context),
              label: AppStrings.readerResultOpenDestination,
              leading: const Icon(Icons.open_in_new, size: 18),
              filled: true,
            )
          else
            Text(
              AppStrings.readerResultNotUrlHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: t.muted, fontSize: 13),
            ),
          const SizedBox(height: 10),
          AppRoundedActionButton(
            onPressed: () => Navigator.of(context).pop(),
            label: AppStrings.readerResultStayInApp,
            leading: const Icon(Icons.home_outlined, size: 18),
            filled: false,
          ),
        ],
      ),
    );
  }

  String _headlineFor(QrAnalysisResult r) {
    if (r.safeToOpen) {
      return 'O destino parece mais seguro. Mesmo assim, confira se o contexto faz sentido.';
    }
    return switch (r.verdict) {
      QrSecurityVerdict.unsafe => 'Evite abrir o destino sem checar. O risco é alto.',
      QrSecurityVerdict.suspicious => 'Atenção: há sinais de risco. Só abra se confiar na origem do QR.',
      QrSecurityVerdict.unknown => 'A análise não foi conclusiva. Siga com cuidado.',
      QrSecurityVerdict.safe => 'Sinais favoráveis, mas a decisão final é sempre sua.',
    };
  }

  bool _looksLikeUrl(String s) {
    final Uri? u = Uri.tryParse(s.trim());
    if (u == null) {
      return false;
    }
    return u.hasScheme && (u.scheme == 'https' || u.scheme == 'http');
  }

  Future<void> _openIfPossible(BuildContext context) async {
    if (!_looksLikeUrl(raw)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.readerResultNotUrlSnack)),
      );
      return;
    }
    final Uri u = Uri.parse(raw.trim());
    if (!await canLaunchUrl(u)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.readerResultCannotOpen)),
      );
      return;
    }
    // Abre o URL no navegador (ou app externo), fora do Safe QR — não usa WebView embutido.
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }
}

final class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.index, required this.text, required this.muted});
  final int index;
  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Text(
              '$index'.padLeft(2, '0'),
              style: GoogleFonts.jetBrainsMono(textStyle: TextStyle(color: muted, fontSize: 12)),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(textStyle: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
