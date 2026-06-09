import type { FastifyInstance } from 'fastify';

import type { Env } from '../config/env.js';
import { HealthController } from '../controllers/health.controller.js';
import { HistoryController } from '../controllers/history.controller.js';
import { QrAnalyzeController } from '../controllers/qr-analyze.controller.js';
import { hasFirebaseCredentials } from '../lib/firebase-admin.js';
import type { Logger } from '../lib/logger.js';
import { createAnalyzeEventPublisher } from '../services/pubsub-analyze-event-publisher.js';
import { FirebaseUserIdentityService } from '../services/firebase-user-identity.service.js';
import { FirestoreHistoryRepository } from '../services/history-firestore.repository.js';
import { InMemoryHistoryRepository } from '../services/history-memory.repository.js';
import { HistoryService } from '../services/history.service.js';
import { QrAnalyzeService } from '../services/qr-analyze.service.js';
import { FirestoreSuspiciousHostsPort } from '../services/suspicious-hosts-firestore.js';
import { NullSuspiciousHostsPort } from '../services/suspicious-hosts-port.js';

function createSuspiciousHostsPort(env: Env) {
  if (!hasFirebaseCredentials(env)) {
    return new NullSuspiciousHostsPort();
  }
  return new FirestoreSuspiciousHostsPort({ cacheTtlMs: env.FIRESTORE_SUSPICIOUS_CACHE_MS });
}

function createHistoryRepository(env: Env) {
  if (hasFirebaseCredentials(env)) {
    return new FirestoreHistoryRepository();
  }
  return new InMemoryHistoryRepository();
}

function createUserIdentity(env: Env) {
  return new FirebaseUserIdentityService({
    allowTestBearer: env.NODE_ENV === 'test',
    verifyTokens: hasFirebaseCredentials(env),
  });
}

export function registerV1Routes(app: FastifyInstance, env: Env, logger: Logger): void {
  const health = new HealthController();
  const userIdentity = createUserIdentity(env);
  const analyzeService = new QrAnalyzeService(createSuspiciousHostsPort(env));
  const eventPublisher = createAnalyzeEventPublisher(env, logger);
  const qrAnalyze = new QrAnalyzeController({
    env,
    service: analyzeService,
    eventPublisher,
    userIdentity,
  });

  const history = new HistoryController({
    service: new HistoryService(createHistoryRepository(env)),
    userIdentity,
  });

  app.get('/v1/health', health.getV1);
  app.get('/health', health.getV1);
  app.post('/v1/qr/analyze', qrAnalyze.postAnalyze);

  app.post('/v1/history', history.postHistory);
  app.get('/v1/history', history.getHistory);
  app.delete('/v1/history/:id', history.deleteHistoryById);
  app.delete('/v1/history', history.clearHistory);
}
