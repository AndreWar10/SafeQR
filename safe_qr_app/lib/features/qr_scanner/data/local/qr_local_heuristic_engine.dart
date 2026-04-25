import 'package:uuid/uuid.dart';

import '../../domain/entities/qr_security_verdict.dart';

/// Heurísticas mínimas alinhadas ao planeamento S1 (sec. 2.3): esquemas perigosos, encurtadores, IP literal, `http` sem TLS.
/// Não substitui listas/ML — apenas viabiliza o app sem API.
final class QrLocalHeuristicEngine {
  const QrLocalHeuristicEngine();

  static const Uuid _uuid = Uuid();
  static const Set<String> _urlShortenerHosts = <String>{
    'bit.ly',
    'tinyurl.com',
    'goo.gl',
    't.co',
    'ow.ly',
    'is.gd',
    'cutt.ly',
    'rebrand.ly',
    'buff.ly',
  };

  QrAnalysisResult evaluate(String raw) {
    final content = raw.trim();
    if (content.isEmpty) {
      return _result(
        verdict: QrSecurityVerdict.unknown,
        safe: false,
        reasons: <String>['Conteúdo vazio.'],
        parsed: const QrParsedSummary(type: 'empty'),
      );
    }
    if (content.toUpperCase().startsWith('WIFI:')) {
      return _result(
        verdict: QrSecurityVerdict.unknown,
        safe: false,
        reasons: <String>['Conteúdo de rede Wi‑Fi. Valide a rede e o sítio onde leu o QR.'],
        parsed: const QrParsedSummary(type: 'wifi'),
      );
    }
    if (content.toUpperCase().contains('BEGIN:VCARD')) {
      return _result(
        verdict: QrSecurityVerdict.unknown,
        safe: false,
        reasons: <String>['Contacto (vCard). A origem ainda importa.'],
        parsed: const QrParsedSummary(type: 'vcard'),
      );
    }

    final uri = Uri.tryParse(content);
    if (uri == null) {
      return _textOnly(content);
    }

    if (uri.hasScheme) {
      final s = uri.scheme.toLowerCase();
      if (s == 'http' || s == 'https') {
        return _httpLike(uri);
      }
      if (s == 'javascript' || s == 'data' || s == 'vbscript' || s == 'file' || s == 'jscript') {
        return _result(
          verdict: QrSecurityVerdict.unsafe,
          safe: false,
          reasons: <String>['Esquema perigoso (`$s`) com impacto de segurança elevado.'],
          parsed: QrParsedSummary(type: s, scheme: s),
        );
      }
      if (s == 'mailto' || s == 'tel' || s == 'sms' || s == 'smsto' || s == 'geo' || s == 'market' || s == 'intent' || s == 'ftp') {
        return _result(
          verdict: QrSecurityVerdict.suspicious,
          safe: false,
          reasons: <String>['Abre aplicação externa (`$s`). Confirme o contexto.'],
          parsed: QrParsedSummary(type: s, scheme: s),
        );
      }
      return _result(
        verdict: QrSecurityVerdict.unknown,
        safe: false,
        reasons: <String>['Esquema $s. A validação aprofundada fica com o serviço remoto (próxima fase).'],
        parsed: QrParsedSummary(type: s, scheme: s),
      );
    }
    if (content.contains('://')) {
      return _textOnly(content, extra: 'Contém `://` mas a URL não pôde ser lida de forma fidedigna.');
    }
    return _textOnly(content);
  }

  QrAnalysisResult _textOnly(String content, {String? extra}) {
    final r = <String>[?extra, 'Não detetámos URL HTTP/HTTPS clara. Verifique a origem física e de quem o enviou.'];
    return _result(
      verdict: QrSecurityVerdict.unknown,
      safe: false,
      reasons: r,
      parsed: const QrParsedSummary(type: 'text'),
    );
  }

  QrAnalysisResult _httpLike(Uri u) {
    if (u.host.isEmpty) {
      return _result(
        verdict: QrSecurityVerdict.unknown,
        safe: false,
        reasons: <String>['Endereço web incompleto ou inválido.'],
        parsed: QrParsedSummary(type: 'url', scheme: u.scheme),
      );
    }
    final host = (u.host).toLowerCase();
    final reasons = <String>[];

    if (u.scheme == 'http') {
      reasons.add('Ligação sem TLS (`http`). A comunicação não é cifrada; prefira `https` quando possível.');
    }
    if (_isIpv4(host) || host == 'localhost' || host == '127.0.0.1') {
      reasons.add('Host com IP explícito ou `localhost` — fácil de disfarçar. Confirme o contexto (rede, evento, estabelecimento).');
    }
    if (_isUrlShortener(host)) {
      reasons.add('Usa redirecionador conhecido: o destino final não fica claro (destino opaco).');
    }

    if (u.scheme == 'https' && reasons.isEmpty && host.isNotEmpty) {
      return _result(
        verdict: QrSecurityVerdict.safe,
        safe: true,
        reasons: <String>[
          'Ligação `https` a um anfitrião textualmente reconhecível (heurística local, não constitui recomendação absoluta).',
        ],
        parsed: QrParsedSummary(
          type: 'url',
          scheme: u.scheme,
          host: u.host,
        ),
      );
    }

    if (u.scheme == 'https' && reasons.isNotEmpty) {
      return _result(
        verdict: QrSecurityVerdict.suspicious,
        safe: false,
        reasons: reasons,
        parsed: QrParsedSummary(
          type: 'url',
          scheme: u.scheme,
          host: u.host,
        ),
      );
    }
    if (u.scheme == 'http') {
      return _result(
        verdict: QrSecurityVerdict.suspicious,
        safe: false,
        reasons: reasons.isEmpty ? <String>['Uso de `http` (sem cifrado) ou combinação de sinais de risco.'] : reasons,
        parsed: QrParsedSummary(
          type: 'url',
          scheme: u.scheme,
          host: u.host,
        ),
      );
    }
    return _result(
      verdict: QrSecurityVerdict.unknown,
      safe: false,
      reasons: <String>['Caso inesperado; valide a origem.'],
      parsed: QrParsedSummary(
        type: 'url',
        scheme: u.scheme,
        host: u.host,
      ),
    );
  }

  static bool _isIpv4(String host) {
    final p = host.split('.');
    if (p.length != 4) {
      return false;
    }
    for (final s in p) {
      final n = int.tryParse(s);
      if (n == null || n < 0 || n > 255) {
        return false;
      }
    }
    return true;
  }

  static bool _isUrlShortener(String host) {
    if (host.isEmpty) {
      return false;
    }
    for (final s in _urlShortenerHosts) {
      if (host == s || host.endsWith('.$s')) {
        return true;
      }
    }
    return false;
  }

  QrAnalysisResult _result({
    required QrSecurityVerdict verdict,
    required bool safe,
    required List<String> reasons,
    required QrParsedSummary parsed,
  }) {
    return QrAnalysisResult(
      requestId: _uuid.v4(),
      verdict: verdict,
      safeToOpen: safe,
      reasons: reasons,
      parsed: parsed,
    );
  }
}
