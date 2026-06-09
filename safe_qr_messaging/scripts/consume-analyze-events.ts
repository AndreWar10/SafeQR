import 'dotenv/config';

import { loadEnv } from '../src/config/env.js';
import { QrAnalyzedHandler } from '../src/handlers/qr-analyzed.handler.js';
import { createLogger } from '../src/lib/logger.js';
import { createScanEventRepository } from '../src/repositories/create-scan-event-repository.js';
import { PubSubSubscriberService } from '../src/services/pubsub-subscriber.service.js';

async function main(): Promise<void> {
  const env = loadEnv();
  const logger = createLogger(env);

  if (!env.CONSUMER_ENABLED) {
    logger.warn('CONSUMER_ENABLED=false — encerrando');
    return;
  }

  const subscriber = new PubSubSubscriberService(env, logger);
  const scanEvents = createScanEventRepository(env, logger);
  const handler = new QrAnalyzedHandler(logger, scanEvents, env.FIRESTORE_COLLECTION);

  await subscriber.start((envelope, message) => handler.handle(envelope, message));

  const shutdown = async (signal: string) => {
    logger.info({ signal }, 'Encerrando consumidor');
    await subscriber.stop();
    process.exit(0);
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

void main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
