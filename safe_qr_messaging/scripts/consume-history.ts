import { resolveHistorySubscription, loadEnv } from '../src/config/env.js';
import { QrAnalyzedHistoryHandler } from '../src/handlers/qr-analyzed-history.handler.js';
import { createHistoryRepository } from '../src/repositories/create-history-repository.js';
import { runConsumer } from './run-consumer.js';

void runConsumer({
  role: 'history',
  subscription: resolveHistorySubscription(loadEnv()),
  createHandler: (env, logger) => {
    const history = createHistoryRepository(env, logger);
    return new QrAnalyzedHistoryHandler(logger, history);
  },
}).catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
