import { describe, expect, it } from 'vitest';

import { qrAnalyzedEnvelopeSchema } from '../src/schemas/qr-analyzed.schema.js';

describe('qrAnalyzedEnvelopeSchema', () => {
  it('aceita envelope válido', () => {
    const parsed = qrAnalyzedEnvelopeSchema.parse({
      schemaVersion: '1',
      eventId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      eventType: 'qr.analyzed',
      occurredAt: '2026-06-08T20:15:30.123Z',
      source: 'safe-qr-api',
      correlationId: 'req-abc',
      data: {
        idUser: 'usr_test',
        contentDigest: 'abc123',
        rawByteLength: 42,
        verdict: 'safe',
        safeToOpen: true,
        reasonCodes: ['HTTPS_OK'],
        reasonsCount: 1,
        parsed: { type: 'url', scheme: 'https', host: 'example.com' },
        client: { platform: 'android', appVersion: '1.0.0' },
        analysisDurationMs: 12,
        historyItem: {
          id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          type: 'scan',
          content: 'https://example.com',
          createdAtMs: 1_700_000_000_000,
          verdict: 'safe',
          safeToOpen: true,
          reasons: ['HTTPS OK'],
        },
      },
    });
    expect(parsed.data.idUser).toBe('usr_test');
    expect(parsed.data.historyItem?.content).toBe('https://example.com');
  });

  it('rejeita eventId inválido', () => {
    expect(() =>
      qrAnalyzedEnvelopeSchema.parse({
        schemaVersion: '1',
        eventId: 'not-a-uuid',
        eventType: 'qr.analyzed',
        occurredAt: '2026-06-08T20:15:30.123Z',
        source: 'safe-qr-api',
        correlationId: 'req-abc',
        data: {
          idUser: null,
          contentDigest: 'abc',
          rawByteLength: 1,
          verdict: 'safe',
          safeToOpen: true,
          reasonCodes: [],
          reasonsCount: 0,
          analysisDurationMs: 1,
        },
      }),
    ).toThrow();
  });
});
