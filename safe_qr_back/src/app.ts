import { randomUUID } from 'node:crypto';

import cors from '@fastify/cors';
import Fastify from 'fastify';
import type { FastifyInstance } from 'fastify';

import type { Env } from './config/env.js';
import type { Logger } from './lib/logger.js';
import { registerV1Routes } from './routes/v1.routes.js';

export async function buildApp(env: Env, logger: Logger): Promise<FastifyInstance> {
  const app = Fastify({
    // Fastify 5: instância Pino vai em `loggerInstance`; `logger` aceita só boolean | objeto de config.
    loggerInstance: logger,
    genReqId: () => randomUUID(),
    requestIdHeader: 'x-request-id',
    disableRequestLogging: false,
  });

  await app.register(cors, {
    origin: true,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-request-id'],
  });

  registerV1Routes(app, env);

  app.setErrorHandler((err, req, reply) => {
    req.log.error({ err }, 'Unhandled error');
    const requestId = req.id;
    if ((err as { validation?: unknown }).validation) {
      return reply.status(400).send({
        error: 'VALIDATION_ERROR',
        message: 'Requisição inválida.',
        requestId,
        details: (err as { validation: unknown }).validation,
      });
    }
    return reply.status(500).send({
      error: 'INTERNAL_ERROR',
      message: 'Erro interno.',
      requestId,
    });
  });

  return app;
}
