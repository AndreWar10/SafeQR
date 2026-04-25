import { randomUUID } from 'node:crypto';

import { QrVerdict, type QrVerdictName } from '../models/qr-verdict.js';
import type { QrAnalyzeResultModel, QrParsedSummary } from '../models/analyze-result.model.js';
import { normalizeHostname } from './suspicious-hosts-match.js';
import { NullSuspiciousHostsPort, type SuspiciousHostsPort } from './suspicious-hosts-port.js';

const URL_SHORTENER_HOSTS = new Set<string>([
  'bit.ly',
  'tinyurl.com',
  'goo.gl',
  't.co',
  'ow.ly',
  'is.gd',
  'cutt.ly',
  'rebrand.ly',
  'buff.ly',
]);

/**
 * Heurística S1 — espelha o motor local do app Flutter (`QrLocalHeuristicEngine`)
 * para resposta estável entre modos local/remoto.
 * Opcionalmente cruza hostname com lista Firestore `suspicious_hosts/clones`.
 */
export class QrAnalyzeService {
  constructor(private readonly suspiciousHosts: SuspiciousHostsPort = new NullSuspiciousHostsPort()) {}

  async evaluateAsync(raw: string): Promise<QrAnalyzeResultModel> {
    const content = raw.trim();
    if (content.length === 0) {
      return this.result({
        verdict: QrVerdict.unknown,
        safe: false,
        reasons: ['Conteúdo vazio.'],
        parsed: { type: 'empty' },
      });
    }

    const upper = content.toUpperCase();
    if (upper.startsWith('WIFI:')) {
      return this.result({
        verdict: QrVerdict.unknown,
        safe: false,
        reasons: ['Conteúdo de rede Wi‑Fi. Valide a rede e o local onde leu o QR.'],
        parsed: { type: 'wifi' },
      });
    }
    if (upper.includes('BEGIN:VCARD')) {
      return this.result({
        verdict: QrVerdict.unknown,
        safe: false,
        reasons: ['Contato (vCard). A origem ainda importa.'],
        parsed: { type: 'vcard' },
      });
    }

    let uri: URL | null = null;
    try {
      uri = new URL(content);
    } catch {
      uri = null;
    }

    if (uri !== null && uri.protocol !== ':') {
      const scheme = uri.protocol.replace(/:$/, '').toLowerCase();
      if (scheme === 'http' || scheme === 'https') {
        if (!uri.hostname) {
          return this.result({
            verdict: QrVerdict.unknown,
            safe: false,
            reasons: ['Endereço web incompleto ou inválido.'],
            parsed: { type: 'url', scheme },
          });
        }
        const norm = normalizeHostname(uri.hostname);
        if (await this.suspiciousHosts.isListedHostname(norm)) {
          const hostRaw = uri.hostname;
          const s = uri.protocol.replace(/:$/, '');
          return this.result({
            verdict: QrVerdict.unsafe,
            safe: false,
            reasons: [
              'Domínio consta na lista de alertas (possível clone / phishing).',
              'Lista gerida no Firestore (`suspicious_hosts/clones`, campo `urls`).',
            ],
            parsed: { type: 'url', scheme: s, host: hostRaw },
          });
        }
        return this.httpLike(uri);
      }
      if (['javascript', 'data', 'vbscript', 'file', 'jscript'].includes(scheme)) {
        return this.result({
          verdict: QrVerdict.unsafe,
          safe: false,
          reasons: [`Esquema perigoso (\`${scheme}\`) com impacto de segurança elevado.`],
          parsed: { type: scheme, scheme },
        });
      }
      if (
        ['mailto', 'tel', 'sms', 'smsto', 'geo', 'market', 'intent', 'ftp'].includes(scheme)
      ) {
        return this.result({
          verdict: QrVerdict.suspicious,
          safe: false,
          reasons: [`Abre aplicação externa (\`${scheme}\`). Confirme o contexto.`],
          parsed: { type: scheme, scheme },
        });
      }
      return this.result({
        verdict: QrVerdict.unknown,
        safe: false,
        reasons: [
          `Esquema ${scheme}. A validação aprofundada fica com o serviço remoto (próxima fase).`,
        ],
        parsed: { type: scheme, scheme },
      });
    }

    if (content.includes('://')) {
      return this.textOnly(content, 'Contém `://` mas a URL não pôde ser lida de forma fidedigna.');
    }
    return this.textOnly(content);
  }

  private textOnly(content: string, extra?: string): QrAnalyzeResultModel {
    const reasons = [
      ...(extra ? [extra] : []),
      'Não detectamos URL HTTP/HTTPS clara. Verifique a origem física e de quem enviou o QR.',
    ];
    return this.result({
      verdict: QrVerdict.unknown,
      safe: false,
      reasons,
      parsed: { type: 'text' },
    });
  }

  private httpLike(u: URL): QrAnalyzeResultModel {
    const hostRaw = u.hostname;
    if (!hostRaw) {
      return this.result({
        verdict: QrVerdict.unknown,
        safe: false,
        reasons: ['Endereço web incompleto ou inválido.'],
        parsed: { type: 'url', scheme: u.protocol.replace(/:$/, '') },
      });
    }

    const host = hostRaw.toLowerCase();
    const scheme = u.protocol.replace(/:$/, '');
    const reasons: string[] = [];

    if (scheme === 'http') {
      reasons.push(
        'Ligação sem TLS (`http`). A comunicação não é cifrada; prefira `https` quando possível.',
      );
    }
    if (this.isIpv4(host) || host === 'localhost' || host === '127.0.0.1') {
      reasons.push(
        'Host com IP explícito ou `localhost` — fácil de disfarçar. Confirme o contexto (rede, evento, estabelecimento).',
      );
    }
    if (this.isUrlShortener(host)) {
      reasons.push('Usa redirecionador conhecido: o destino final não fica claro (destino opaco).');
    }

    const parsed: QrParsedSummary = { type: 'url', scheme, host: hostRaw };

    if (scheme === 'https' && reasons.length === 0) {
      return this.result({
        verdict: QrVerdict.safe,
        safe: true,
        reasons: [
          'Ligação `https` a um host textualmente reconhecível (heurística; não é recomendação absoluta).',
        ],
        parsed,
      });
    }

    if (scheme === 'https' && reasons.length > 0) {
      return this.result({
        verdict: QrVerdict.suspicious,
        safe: false,
        reasons,
        parsed,
      });
    }

    if (scheme === 'http') {
      return this.result({
        verdict: QrVerdict.suspicious,
        safe: false,
        reasons:
          reasons.length === 0
            ? ['Uso de `http` (sem cifrado) ou combinação de sinais de risco.']
            : reasons,
        parsed,
      });
    }

    return this.result({
      verdict: QrVerdict.unknown,
      safe: false,
      reasons: ['Caso inesperado; valide a origem.'],
      parsed,
    });
  }

  private isIpv4(host: string): boolean {
    const p = host.split('.');
    if (p.length !== 4) return false;
    for (const s of p) {
      const n = Number(s);
      if (!Number.isInteger(n) || n < 0 || n > 255) return false;
    }
    return true;
  }

  private isUrlShortener(host: string): boolean {
    if (!host) return false;
    for (const s of URL_SHORTENER_HOSTS) {
      if (host === s || host.endsWith(`.${s}`)) return true;
    }
    return false;
  }

  private result(input: {
    verdict: QrVerdictName;
    safe: boolean;
    reasons: string[];
    parsed: QrParsedSummary;
  }): QrAnalyzeResultModel {
    return {
      requestId: randomUUID(),
      verdict: input.verdict,
      safeToOpen: input.safe,
      reasons: input.reasons,
      parsed: input.parsed,
    };
  }
}
