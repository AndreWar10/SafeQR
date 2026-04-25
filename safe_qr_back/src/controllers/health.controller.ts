import type { FastifyReply, FastifyRequest } from 'fastify';

export class HealthController {
  getV1 = async (_req: FastifyRequest, reply: FastifyReply) => {
    return reply.send({
      status: 'ok',
      service: 'safe-qr-api',
      version: process.env.npm_package_version ?? '0.1.0',
    });
  };
}
