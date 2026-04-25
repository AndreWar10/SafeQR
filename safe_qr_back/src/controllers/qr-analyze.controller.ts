import { createHash } from 'node:crypto';

import type { FastifyReply, FastifyRequest } from 'fastify';

import type { Env } from '../config/env.js';
import { qrAnalyzeBodySchema } from '../schemas/qr-analyze.schema.js';
import type { QrAnalyzeService } from '../services/qr-analyze.service.js';
import { payloadTooLarge, validationError } from '../views/error-response.view.js';
import { toQrAnalyzeResponseJson } from '../views/qr-analyze-response.view.js';

type AnalyzeDeps = {
  env: Env;
  service: QrAnalyzeService;
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
      },
      'Análise de QR solicitada',
    );

    const model = await this.deps.service.evaluateAsync(rawContent);
    return reply.send(toQrAnalyzeResponseJson(model));
  };
}
