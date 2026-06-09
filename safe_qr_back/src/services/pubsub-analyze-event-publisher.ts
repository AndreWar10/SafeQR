import { randomUUID } from 'node:crypto';

import { PubSub } from '@google-cloud/pubsub';

import type { Env } from '../config/env.js';
import type { Logger } from '../lib/logger.js';
import type {
  AnalyzeEventPublisherPort,
  QrAnalyzedPublishInput,
} from './analyze-event-publisher.port.js';
import { buildQrAnalyzedHistoryItem } from './build-qr-analyzed-history-item.js';
import { NullAnalyzeEventPublisher } from './null-analyze-event-publisher.js';

export class PubSubAnalyzeEventPublisher implements AnalyzeEventPublisherPort {
  private readonly topic;

  constructor(
    env: Env,
    private readonly logger: Logger,
  ) {
    const clientOptions: { projectId: string; keyFilename?: string } = {
      projectId: env.GCP_PROJECT_ID!,
    };
    const keyFile =
      env.PUBSUB_GOOGLE_APPLICATION_CREDENTIALS?.trim() ||
      env.GOOGLE_APPLICATION_CREDENTIALS?.trim();
    if (keyFile) {
      clientOptions.keyFilename = keyFile;
    }
    const pubsub = new PubSub(clientOptions);
    this.topic = pubsub.topic(env.PUBSUB_TOPIC);
  }

  async publishQrAnalyzed(input: QrAnalyzedPublishInput): Promise<void> {
    const eventId = randomUUID();
    const createdAtMs = Date.now();
    const historyItem =
      input.idUser != null
        ? buildQrAnalyzedHistoryItem(eventId, input.rawContent, input.model, createdAtMs)
        : undefined;

    const envelope = {
      schemaVersion: '1' as const,
      eventId,
      eventType: 'qr.analyzed' as const,
      occurredAt: new Date(createdAtMs).toISOString(),
      source: 'safe-qr-api' as const,
      correlationId: input.correlationId,
      data: {
        idUser: input.idUser,
        contentDigest: input.contentDigest,
        rawByteLength: input.rawByteLength,
        verdict: input.model.verdict,
        safeToOpen: input.model.safeToOpen,
        reasonCodes: input.reasonCodes,
        reasonsCount: input.model.reasons.length,
        parsed: {
          ...(input.model.parsed.type !== undefined ? { type: input.model.parsed.type } : {}),
          ...(input.model.parsed.scheme !== undefined ? { scheme: input.model.parsed.scheme } : {}),
          ...(input.model.parsed.host !== undefined ? { host: input.model.parsed.host } : {}),
        },
        client: {
          ...(input.client?.platform !== undefined ? { platform: input.client.platform } : {}),
          ...(input.client?.appVersion !== undefined ? { appVersion: input.client.appVersion } : {}),
        },
        analysisDurationMs: input.analysisDurationMs,
        ...(historyItem !== undefined ? { historyItem } : {}),
      },
    };

    if (input.idUser == null) {
      this.logger.warn(
        {
          event: 'pubsub_qr_analyzed_no_iduser',
          correlationId: input.correlationId,
          eventId: envelope.eventId,
        },
        'Publicando qr.analyzed sem idUser — consumidor history ignorará',
      );
    }

    await this.topic.publishMessage({
      json: envelope,
      attributes: {
        eventType: 'qr.analyzed',
        schemaVersion: '1',
        verdict: input.model.verdict,
      },
    });

    this.logger.info(
      {
        event: 'pubsub_qr_analyzed_published',
        eventId: envelope.eventId,
        correlationId: input.correlationId,
        idUser: input.idUser,
        hasHistoryItem: historyItem !== undefined,
        verdict: input.model.verdict,
      },
      'Evento qr.analyzed publicado',
    );
  }
}

export function createAnalyzeEventPublisher(env: Env, logger: Logger): AnalyzeEventPublisherPort {
  if (!env.PUBSUB_ENABLED || !env.GCP_PROJECT_ID) {
    return new NullAnalyzeEventPublisher();
  }
  return new PubSubAnalyzeEventPublisher(env, logger);
}
