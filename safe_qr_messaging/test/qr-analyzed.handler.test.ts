import { describe, expect, it, vi } from 'vitest';

import { QrAnalyzedHandler } from '../src/handlers/qr-analyzed.handler.js';
import { createLogger } from '../src/lib/logger.js';
import type { ScanEventRepository } from '../src/repositories/scan-event-repository.port.js';
import { qrAnalyzedEnvelopeSchema } from '../src/schemas/qr-analyzed.schema.js';

const envelope = qrAnalyzedEnvelopeSchema.parse({
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

describe('QrAnalyzedHandler', () => {
  it('persiste evento antes de logar', async () => {
    const save = vi.fn<ScanEventRepository['save']>().mockResolvedValue('created');
    const repo: ScanEventRepository = { save };
    const logger = createLogger({
      NODE_ENV: 'test',
      LOG_LEVEL: 'silent',
      GCP_PROJECT_ID: 'safe-qr-app',
      PUBSUB_SUBSCRIPTION: 'safe-qr-analyze-events-sub',
      CONSUMER_ENABLED: true,
      CONSUMER_MAX_MESSAGES: 10,
      CONSUMER_ACK_DEADLINE_SEC: 60,
      FIRESTORE_ENABLED: true,
      FIRESTORE_COLLECTION: 'scan_events',
    });

    const handler = new QrAnalyzedHandler(logger, repo, 'scan_events');
    await handler.handle(envelope, { id: 'msg-1' } as never);

    expect(save).toHaveBeenCalledWith(envelope);
  });
});
