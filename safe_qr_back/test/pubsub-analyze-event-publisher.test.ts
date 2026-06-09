import { describe, expect, it, vi, beforeEach } from 'vitest';

import { loadEnv } from '../src/config/env.js';
import { createLogger } from '../src/lib/logger.js';
import { PubSubAnalyzeEventPublisher } from '../src/services/pubsub-analyze-event-publisher.js';

const UID = 'Vb3ubOjy9RYt9AKpx3VzunBirEc2';

vi.mock('@google-cloud/pubsub', () => {
  const publishMessage = vi.fn().mockResolvedValue('msg-1');
  return {
    PubSub: vi.fn().mockImplementation(() => ({
      topic: () => ({ publishMessage }),
    })),
    __publishMessage: publishMessage,
  };
});

describe('PubSubAnalyzeEventPublisher', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('inclui historyItem quando idUser presente', async () => {
    const env = loadEnv({
      NODE_ENV: 'test',
      LOG_LEVEL: 'fatal',
      PUBSUB_ENABLED: 'true',
      GCP_PROJECT_ID: 'safe-qr-app',
      PUBSUB_TOPIC: 'safe-qr-analyze-events',
    });
    const logger = createLogger(env);
    const publisher = new PubSubAnalyzeEventPublisher(env, logger);

    await publisher.publishQrAnalyzed({
      correlationId: 'corr-1',
      idUser: UID,
      rawContent: 'https://example.com',
      contentDigest: 'abc123',
      rawByteLength: 19,
      model: {
        requestId: 'model-req',
        verdict: 'safe',
        safeToOpen: true,
        reasons: ['HTTPS OK'],
        parsed: { type: 'url', scheme: 'https', host: 'example.com' },
      },
      reasonCodes: ['HTTPS_OK'],
      client: { platform: 'android', appVersion: '1.0.0' },
      analysisDurationMs: 42,
    });

    const { PubSub } = await import('@google-cloud/pubsub');
    const pubsub = new PubSub({ projectId: 'safe-qr-app' });
    const topic = pubsub.topic('safe-qr-analyze-events');
    const call = (topic.publishMessage as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as {
      json: {
        eventId: string;
        eventType: string;
        data: {
          idUser: string;
          historyItem: { id: string; type: string; content: string };
        };
      };
      attributes: Record<string, string>;
    };

    expect(call.json.eventType).toBe('qr.analyzed');
    expect(call.json.data.idUser).toBe(UID);
    expect(call.json.data.historyItem.type).toBe('scan');
    expect(call.json.data.historyItem.id).toBe(call.json.eventId);
    expect(call.json.data.historyItem.content).toBe('https://example.com');
    expect(call.attributes).toEqual({
      eventType: 'qr.analyzed',
      schemaVersion: '1',
      verdict: 'safe',
    });
  });

  it('omite historyItem quando idUser ausente', async () => {
    const env = loadEnv({
      NODE_ENV: 'test',
      LOG_LEVEL: 'fatal',
      PUBSUB_ENABLED: 'true',
      GCP_PROJECT_ID: 'safe-qr-app',
    });
    const publisher = new PubSubAnalyzeEventPublisher(env, createLogger(env));

    await publisher.publishQrAnalyzed({
      correlationId: 'corr-2',
      idUser: null,
      rawContent: 'https://example.com',
      contentDigest: 'abc123',
      rawByteLength: 19,
      model: {
        requestId: 'model-req',
        verdict: 'safe',
        safeToOpen: true,
        reasons: [],
        parsed: { type: 'url' },
      },
      reasonCodes: ['HTTPS_OK'],
      analysisDurationMs: 10,
    });

    const { PubSub } = await import('@google-cloud/pubsub');
    const topic = new PubSub({ projectId: 'safe-qr-app' }).topic('safe-qr-analyze-events');
    const call = (topic.publishMessage as ReturnType<typeof vi.fn>).mock.calls[0]?.[0] as {
      json: { data: { idUser: null; historyItem?: unknown } };
    };

    expect(call.json.data.idUser).toBeNull();
    expect(call.json.data.historyItem).toBeUndefined();
  });
});
