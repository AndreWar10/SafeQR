import type { Env } from '../config/env.js';
import type { Logger } from '../lib/logger.js';
import { FirestoreScanEventRepository } from './firestore-scan-event.repository.js';
import { NullScanEventRepository } from './null-scan-event.repository.js';
import type { ScanEventRepository } from './scan-event-repository.port.js';

export function createScanEventRepository(env: Env, logger: Logger): ScanEventRepository {
  if (!env.FIRESTORE_ENABLED) {
    logger.warn('FIRESTORE_ENABLED=false — eventos não serão persistidos');
    return new NullScanEventRepository();
  }

  return new FirestoreScanEventRepository(env, logger);
}
