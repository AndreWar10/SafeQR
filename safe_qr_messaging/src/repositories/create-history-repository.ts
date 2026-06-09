import type { Env } from '../config/env.js';
import type { Logger } from '../lib/logger.js';
import { FirestoreHistoryRepository } from './firestore-history.repository.js';
import type { HistoryRepository } from './history-repository.port.js';
import { NullHistoryRepository } from './null-history.repository.js';

export function createHistoryRepository(env: Env, logger: Logger): HistoryRepository {
  if (!env.FIRESTORE_ENABLED) {
    logger.warn('FIRESTORE_ENABLED=false — histórico não será persistido');
    return new NullHistoryRepository();
  }

  return new FirestoreHistoryRepository(env, logger);
}
