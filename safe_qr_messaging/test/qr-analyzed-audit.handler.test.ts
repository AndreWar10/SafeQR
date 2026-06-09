import { describe, expect, it, vi } from 'vitest';

import { QrAnalyzedAuditHandler } from '../src/handlers/qr-analyzed-audit.handler.js';
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

const baseEnv = {
  NODE_ENV: 'test' as const,
  LOG_LEVEL: 'silent' as const,
  GCP_PROJECT_ID: 'safe-qr-app',
  PUBSUB_SUBSCRIPTION: 'safe-qr-analyze-events-sub',
  CONSUMER_ENABLED: true,
  CONSUMER_MAX_MESSAGES: 10,
  CONSUMER_ACK_DEADLINE_SEC: 60,
  FIRESTORE_ENABLED: true,
  FIRESTORE_COLLECTION: 'scan_events',
  FIRESTORE_HISTORY_COLLECTION: 'history',
  FIRESTORE_HISTORY_ITEMS_SUBCOLLECTION: 'items',
};

describe('QrAnalyzedAuditHandler', () => {
  it('persiste scan_events antes de logar', async () => {
    const save = vi.fn<ScanEventRepository['save']>().mockResolvedValue('created');
    const repo: ScanEventRepository = { save };
    const logger = createLogger(baseEnv);
    const handler = new QrAnalyzedAuditHandler(logger, repo, 'scan_events');

    await handler.handle(envelope, { id: 'msg-1' } as never);

    expect(save).toHaveBeenCalledWith(envelope);
  });
});
