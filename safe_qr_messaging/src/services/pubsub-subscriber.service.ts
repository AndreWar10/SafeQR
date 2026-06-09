import type { Message, Subscription } from '@google-cloud/pubsub';
import { PubSub } from '@google-cloud/pubsub';

import type { Env } from '../config/env.js';
import type { Logger } from '../lib/logger.js';
import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';
import { qrAnalyzedEnvelopeSchema } from '../schemas/qr-analyzed.schema.js';
import { ProcessedEventCache } from './processed-event-cache.js';

export type MessageHandler = (envelope: QrAnalyzedEnvelope, message: Message) => Promise<void>;

export class PubSubSubscriberService {
  private subscription: Subscription | null = null;
  private readonly dedupe = new ProcessedEventCache();

  constructor(
    private readonly env: Env,
    private readonly logger: Logger,
    private readonly subscriptionName: string = env.PUBSUB_SUBSCRIPTION,
  ) {}

  async start(onMessage: MessageHandler): Promise<void> {
    const clientOptions: { projectId: string; keyFilename?: string } = {
      projectId: this.env.GCP_PROJECT_ID,
    };
    if (this.env.GOOGLE_APPLICATION_CREDENTIALS?.trim()) {
      clientOptions.keyFilename = this.env.GOOGLE_APPLICATION_CREDENTIALS.trim();
    }

    const pubsub = new PubSub(clientOptions);
    this.subscription = pubsub.subscription(this.subscriptionName, {
      flowControl: { maxMessages: this.env.CONSUMER_MAX_MESSAGES },
    });

    this.subscription.on('message', (message: Message) => {
      void this.handleMessage(message, onMessage);
    });

    this.subscription.on('error', (err: Error) => {
      this.logger.error({ err }, 'Erro na subscription Pub/Sub');
    });

    this.logger.info(
      {
        subscription: this.subscriptionName,
        projectId: this.env.GCP_PROJECT_ID,
      },
      'Consumidor Pub/Sub ativo (aguardando mensagens)',
    );
  }

  async stop(): Promise<void> {
    if (this.subscription) {
      await this.subscription.close();
      this.subscription = null;
    }
  }

  private async handleMessage(message: Message, onMessage: MessageHandler): Promise<void> {
    try {
      const raw = message.data.toString('utf8');
      const json: unknown = JSON.parse(raw);
      const envelope = qrAnalyzedEnvelopeSchema.parse(json);

      if (this.dedupe.has(envelope.eventId)) {
        this.logger.info({ eventId: envelope.eventId }, 'Evento duplicado — ack');
        message.ack();
        return;
      }

      await onMessage(envelope, message);
      this.dedupe.add(envelope.eventId);
      message.ack();
    } catch (err) {
      this.logger.error(
        { err, messageId: message.id, deliveryAttempt: message.deliveryAttempt },
        'Falha ao processar mensagem',
      );
      message.nack();
    }
  }
}
