import { describe, expect, it } from 'vitest';

import { deriveReasonCodes } from '../src/services/derive-reason-codes.js';
import { QrVerdict } from '../src/models/qr-verdict.js';

describe('deriveReasonCodes', () => {
  it('https safe → HTTPS_OK', () => {
    const codes = deriveReasonCodes({
      requestId: 'x',
      verdict: QrVerdict.safe,
      safeToOpen: true,
      reasons: ['Ligação `https` a um host textualmente reconhecível'],
      parsed: { type: 'url', scheme: 'https', host: 'example.com' },
    });
    expect(codes).toContain('HTTPS_OK');
  });

  it('bit.ly → SHORTENER', () => {
    const codes = deriveReasonCodes({
      requestId: 'x',
      verdict: QrVerdict.suspicious,
      safeToOpen: false,
      reasons: ['Usa redirecionador conhecido'],
      parsed: { type: 'url', scheme: 'https', host: 'bit.ly' },
    });
    expect(codes).toContain('SHORTENER');
  });
});
