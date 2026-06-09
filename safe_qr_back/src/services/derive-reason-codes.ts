import type { QrAnalyzeResultModel } from '../models/analyze-result.model.js';

const EXTERNAL_SCHEMES = new Set([
  'mailto',
  'tel',
  'sms',
  'smsto',
  'geo',
  'market',
  'intent',
  'ftp',
]);

const UNSAFE_SCHEMES = new Set(['javascript', 'data', 'vbscript', 'file', 'jscript']);

/** Deriva reasonCodes estáveis a partir do resultado da heurística. */
export function deriveReasonCodes(model: QrAnalyzeResultModel): string[] {
  const codes = new Set<string>();
  const parsed = model.parsed;
  const reasonsText = model.reasons.join(' ').toLowerCase();
  const type = parsed.type ?? '';

  if (type === 'empty') {
    codes.add('EMPTY');
  }
  if (type === 'wifi') {
    codes.add('WIFI');
  }
  if (type === 'vcard') {
    codes.add('VCARD');
  }
  if (reasonsText.includes('lista de alertas') || reasonsText.includes('firestore')) {
    codes.add('BLOCKLIST_MATCH');
  }
  if (UNSAFE_SCHEMES.has(type)) {
    codes.add('UNSAFE_SCHEME');
  }
  if (reasonsText.includes('sem tls') || reasonsText.includes('`http`')) {
    codes.add('HTTP_INSECURE');
  }
  if (reasonsText.includes('redirecionador')) {
    codes.add('SHORTENER');
  }
  if (
    reasonsText.includes('localhost') ||
    reasonsText.includes('ip explícito') ||
    reasonsText.includes('ip literal')
  ) {
    codes.add('LITERAL_IP');
  }
  if (EXTERNAL_SCHEMES.has(type)) {
    codes.add('EXTERNAL_SCHEME');
  }
  if (model.verdict === 'safe' && codes.size === 0) {
    codes.add('HTTPS_OK');
  }
  if (codes.size === 0) {
    codes.add('UNKNOWN');
  }

  return [...codes].sort();
}
