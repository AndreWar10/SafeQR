import { describe, expect, it, vi } from 'vitest';

import { QrAnalyzedHistoryHandler } from '../src/handlers/qr-analyzed-history.handler.js';
import { createLogger } from '../src/lib/logger.js';
import type { HistoryRepository } from '../src/repositories/history-repository.port.js';
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

describe('QrAnalyzedHistoryHandler', () => {
  it('persiste item no histórico', async () => {
    const save = vi.fn<HistoryRepository['save']>().mockResolvedValue('created');
    const repo: HistoryRepository = { save };
    const logger = createLogger({
      NODE_ENV: 'test',
      LOG_LEVEL: 'silent',
      GCP_PROJECT_ID: 'safe-qr-app',
      PUBSUB_SUBSCRIPTION: 'safe-qr-analyze-events-sub-history',
      CONSUMER_ENABLED: true,
      CONSUMER_MAX_MESSAGES: 10,
      CONSUMER_ACK_DEADLINE_SEC: 60,
      FIRESTORE_ENABLED: true,
      FIRESTORE_COLLECTION: 'scan_events',
      FIRESTORE_HISTORY_COLLECTION: 'history',
      FIRESTORE_HISTORY_ITEMS_SUBCOLLECTION: 'items',
    });

    const handler = new QrAnalyzedHistoryHandler(logger, repo);
    await handler.handle(envelope, { id: 'msg-1' } as never);

    expect(save).toHaveBeenCalledWith({
      idUser: 'usr_test',
      eventId: envelope.eventId,
      correlationId: 'req-abc',
      item: envelope.data.historyItem,
    });
  });

  it('ignora evento sem idUser', async () => {
    const save = vi.fn<HistoryRepository['save']>();
    const handler = new QrAnalyzedHistoryHandler(
      createLogger({
        NODE_ENV: 'test',
        LOG_LEVEL: 'silent',
        GCP_PROJECT_ID: 'safe-qr-app',
        PUBSUB_SUBSCRIPTION: 'safe-qr-analyze-events-sub-history',
        CONSUMER_ENABLED: true,
        CONSUMER_MAX_MESSAGES: 10,
        CONSUMER_ACK_DEADLINE_SEC: 60,
        FIRESTORE_ENABLED: true,
        FIRESTORE_COLLECTION: 'scan_events',
        FIRESTORE_HISTORY_COLLECTION: 'history',
        FIRESTORE_HISTORY_ITEMS_SUBCOLLECTION: 'items',
      }),
      { save },
    );

    const withoutUser = {
      ...envelope,
      data: { ...envelope.data, idUser: null, historyItem: undefined },
    };

    await handler.handle(withoutUser, { id: 'msg-2' } as never);

    expect(save).not.toHaveBeenCalled();
  });
});
