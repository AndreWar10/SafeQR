import type { FastifyInstance } from 'fastify';

import type { Env } from '../config/env.js';
import { HealthController } from '../controllers/health.controller.js';
import { QrAnalyzeController } from '../controllers/qr-analyze.controller.js';
import { QrAnalyzeService } from '../services/qr-analyze.service.js';

export function registerV1Routes(app: FastifyInstance, env: Env): void {
  const health = new HealthController();
  const analyzeService = new QrAnalyzeService();
  const qrAnalyze = new QrAnalyzeController({ env, service: analyzeService });

  app.get('/v1/health', health.getV1);
  app.get('/health', health.getV1);
  app.post('/v1/qr/analyze', qrAnalyze.postAnalyze);
}
