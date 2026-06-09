import { resolveAuditSubscription, loadEnv } from '../src/config/env.js';
import { QrAnalyzedAuditHandler } from '../src/handlers/qr-analyzed-audit.handler.js';
import { createScanEventRepository } from '../src/repositories/create-scan-event-repository.js';
import { runConsumer } from './run-consumer.js';

void runConsumer({
  role: 'audit',
  subscription: resolveAuditSubscription(loadEnv()),
  createHandler: (env, logger) => {
    const scanEvents = createScanEventRepository(env, logger);
    return new QrAnalyzedAuditHandler(logger, scanEvents, env.FIRESTORE_COLLECTION);
  },
}).catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
