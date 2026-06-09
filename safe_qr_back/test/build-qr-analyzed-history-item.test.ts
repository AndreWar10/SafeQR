import { describe, expect, it } from 'vitest';

import {
  buildQrAnalyzedHistoryItem,
  clipHistoryContent,
} from '../src/services/build-qr-analyzed-history-item.js';

describe('buildQrAnalyzedHistoryItem', () => {
  it('monta item de histórico para scan', () => {
    const item = buildQrAnalyzedHistoryItem(
      'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      'https://example.com',
      {
        requestId: 'req-1',
        verdict: 'safe',
        safeToOpen: true,
        reasons: ['HTTPS OK'],
        parsed: { type: 'url', scheme: 'https', host: 'example.com' },
      },
      1_700_000_000_000,
    );

    expect(item).toEqual({
      id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      type: 'scan',
      content: 'https://example.com',
      createdAtMs: 1_700_000_000_000,
      verdict: 'safe',
      safeToOpen: true,
      reasons: ['HTTPS OK'],
    });
  });

  it('trunca conteúdo longo', () => {
    const long = 'a'.repeat(2500);
    expect(clipHistoryContent(long).length).toBe(2000);
  });
});
