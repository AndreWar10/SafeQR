import 'dotenv/config';

import { loadEnv, type Env } from '../src/config/env.js';
import { createLogger, type Logger } from '../src/lib/logger.js';
import type { QrAnalyzedEnvelope } from '../src/schemas/qr-analyzed.schema.js';
import { PubSubSubscriberService } from '../src/services/pubsub-subscriber.service.js';
import type { Message } from '@google-cloud/pubsub';

export type ConsumerRunnerOptions = {
  role: 'audit' | 'history';
  subscription: string;
  createHandler: (env: Env, logger: Logger) => {
    handle: (envelope: QrAnalyzedEnvelope, message: Message) => Promise<void>;
  };
};

export async function runConsumer(options: ConsumerRunnerOptions): Promise<void> {
  const env = loadEnv();
  const logger = createLogger(env).child({ consumer: options.role });

  if (!env.CONSUMER_ENABLED) {
    logger.warn('CONSUMER_ENABLED=false — encerrando');
    return;
  }

  const subscriber = new PubSubSubscriberService(env, logger, options.subscription);
  const handler = options.createHandler(env, logger);

  await subscriber.start((envelope, message) => handler.handle(envelope, message));

  const shutdown = async (signal: string) => {
    logger.info({ signal }, 'Encerrando consumidor');
    await subscriber.stop();
    process.exit(0);
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}
