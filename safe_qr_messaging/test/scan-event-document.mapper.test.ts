import { describe, expect, it } from 'vitest';

import { mapEnvelopeToScanEventDocument } from '../src/mappers/scan-event-document.mapper.js';
import { qrAnalyzedEnvelopeSchema } from '../src/schemas/qr-analyzed.schema.js';

const sampleEnvelope = qrAnalyzedEnvelopeSchema.parse({
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
  },
});

describe('mapEnvelopeToScanEventDocument', () => {
  it('mapeia envelope para documento Firestore', () => {
    const doc = mapEnvelopeToScanEventDocument(sampleEnvelope);

    expect(doc.eventId).toBe(sampleEnvelope.eventId);
    expect(doc.idUser).toBe('usr_test');
    expect(doc.verdict).toBe('safe');
    expect(doc.parsed?.host).toBe('example.com');
    expect(doc.occurredAt.toDate().toISOString()).toBe('2026-06-08T20:15:30.123Z');
    expect(doc.consumedAt).toBeDefined();
  });
});
