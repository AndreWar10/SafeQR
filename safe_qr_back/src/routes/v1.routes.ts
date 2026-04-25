import type { FastifyInstance } from 'fastify';

import type { Env } from '../config/env.js';
import { HealthController } from '../controllers/health.controller.js';
import { QrAnalyzeController } from '../controllers/qr-analyze.controller.js';
import { QrAnalyzeService } from '../services/qr-analyze.service.js';
import { FirestoreSuspiciousHostsPort } from '../services/suspicious-hosts-firestore.js';
import { NullSuspiciousHostsPort } from '../services/suspicious-hosts-port.js';

function createSuspiciousHostsPort(env: Env) {
  const hasCredPath = Boolean(env.GOOGLE_APPLICATION_CREDENTIALS?.trim());
  const hasCredJson = Boolean(env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim());
  if (!hasCredPath && !hasCredJson) {
    return new NullSuspiciousHostsPort();
  }
  return new FirestoreSuspiciousHostsPort({ cacheTtlMs: env.FIRESTORE_SUSPICIOUS_CACHE_MS });
}

export function registerV1Routes(app: FastifyInstance, env: Env): void {
  const health = new HealthController();
  const analyzeService = new QrAnalyzeService(createSuspiciousHostsPort(env));
  const qrAnalyze = new QrAnalyzeController({ env, service: analyzeService });

  app.get('/v1/health', health.getV1);
  app.get('/health', health.getV1);
  app.post('/v1/qr/analyze', qrAnalyze.postAnalyze);
}
