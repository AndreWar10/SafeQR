import { createHash } from 'node:crypto';

import type { FastifyReply, FastifyRequest } from 'fastify';

import type { Env } from '../config/env.js';
import { qrAnalyzeBodySchema } from '../schemas/qr-analyze.schema.js';
import type { AnalyzeEventPublisherPort } from '../services/analyze-event-publisher.port.js';
import { deriveReasonCodes } from '../services/derive-reason-codes.js';
import type { QrAnalyzeService } from '../services/qr-analyze.service.js';
import { payloadTooLarge, validationError } from '../views/error-response.view.js';
import { toQrAnalyzeResponseJson } from '../views/qr-analyze-response.view.js';

type AnalyzeDeps = {
  env: Env;
  service: QrAnalyzeService;
  eventPublisher: AnalyzeEventPublisherPort;
};

/**
 * Orquestra validação de entrada, limites e delegação ao serviço (camada Controller).
 * A serialização final fica na View.
 */
export class QrAnalyzeController {
  constructor(private readonly deps: AnalyzeDeps) {}

  postAnalyze = async (req: FastifyRequest, reply: FastifyReply) => {
    const requestId = req.id;
    const parsed = qrAnalyzeBodySchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send(
        validationError(requestId, 'Corpo inválido.', parsed.error.flatten()),
      );
    }

    const { rawContent, client } = parsed.data;
    const byteLen = Buffer.byteLength(rawContent, 'utf8');
    if (byteLen > this.deps.env.MAX_RAW_CONTENT_BYTES) {
      return reply
        .status(413)
        .send(payloadTooLarge(requestId, this.deps.env.MAX_RAW_CONTENT_BYTES));
    }

    const contentDigest = createHash('sha256').update(rawContent, 'utf8').digest('hex').slice(0, 16);

    req.log.info(
      {
        event: 'qr_analyze',
        rawByteLength: byteLen,
        contentDigest,
        clientPlatform: client?.platform,
        clientAppVersion: client?.appVersion,
        idUser: client?.idUser,
      },
      'Análise de QR solicitada',
    );

    const startedAt = Date.now();
    const model = await this.deps.service.evaluateAsync(rawContent);
    const analysisDurationMs = Date.now() - startedAt;
    const body = toQrAnalyzeResponseJson(model);

    void this.deps.eventPublisher
      .publishQrAnalyzed({
        correlationId: requestId,
        idUser: client?.idUser ?? null,
        contentDigest,
        rawByteLength: byteLen,
        model,
        reasonCodes: deriveReasonCodes(model),
        client,
        analysisDurationMs,
      })
      .catch((err: unknown) => {
        req.log.warn({ err, event: 'pubsub_publish_failed' }, 'Falha ao publicar qr.analyzed');
      });

    return reply.send(body);
  };
}
