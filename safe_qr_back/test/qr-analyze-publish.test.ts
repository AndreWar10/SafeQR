import { describe, expect, it } from 'vitest';

import type { FastifyReply, FastifyRequest } from 'fastify';

import { QrAnalyzeController } from '../src/controllers/qr-analyze.controller.js';
import { loadEnv } from '../src/config/env.js';
import type {
  AnalyzeEventPublisherPort,
  QrAnalyzedPublishInput,
} from '../src/services/analyze-event-publisher.port.js';
import { QrAnalyzeService } from '../src/services/qr-analyze.service.js';
import type { ResolveIdUserResult, UserIdentityPort } from '../src/services/user-identity.port.js';

const UID = 'Vb3ubOjy9RYt9AKpx3VzunBirEc2';

class CapturingPublisher implements AnalyzeEventPublisherPort {
  published: QrAnalyzedPublishInput[] = [];
  async publishQrAnalyzed(input: QrAnalyzedPublishInput): Promise<void> {
    this.published.push(input);
  }
}

class StubIdentity implements UserIdentityPort {
  constructor(private readonly result: ResolveIdUserResult) {}
  async resolveBearerUid(): Promise<ResolveIdUserResult> {
    return this.result;
  }
}

function mockReq(body: unknown, auth?: string): FastifyRequest {
  return {
    id: 'req-test-uuid',
    body,
    headers: auth ? { authorization: auth } : {},
    log: {
      info: () => {},
      warn: () => {},
      error: () => {},
      fatal: () => {},
      debug: () => {},
      trace: () => {},
      child: () => mockReq(body, auth).log,
    },
  } as unknown as FastifyRequest;
}

function mockReply(): FastifyReply {
  const reply = {
    statusCode: 200,
    status(code: number) {
      reply.statusCode = code;
      return reply;
    },
    send(payload: unknown) {
      reply.payload = payload;
      return reply;
    },
    payload: undefined as unknown,
  };
  return reply as unknown as FastifyReply;
}

describe('QrAnalyzeController — Pub/Sub idUser', () => {
  const env = loadEnv({ NODE_ENV: 'test', LOG_LEVEL: 'fatal' });

  it('publica com idUser do Bearer', async () => {
    const publisher = new CapturingPublisher();
    const controller = new QrAnalyzeController({
      env,
      service: new QrAnalyzeService(),
      eventPublisher: publisher,
      userIdentity: new StubIdentity({ ok: true, idUser: UID }),
    });

    const reply = mockReply();
    await controller.postAnalyze(
      mockReq(
        {
          rawContent: 'https://example.com',
          client: { idUser: 'outro-uid', platform: 'android' },
        },
        'Bearer eyJ-test',
      ),
      reply,
    );

    expect(reply.statusCode).toBe(200);
    expect(publisher.published).toHaveLength(1);
    expect(publisher.published[0]?.idUser).toBe(UID);
  });

  it('401 sem Bearer — não publica', async () => {
    const publisher = new CapturingPublisher();
    const controller = new QrAnalyzeController({
      env,
      service: new QrAnalyzeService(),
      eventPublisher: publisher,
      userIdentity: new StubIdentity({ ok: false, reason: 'missing' }),
    });

    const reply = mockReply();
    await controller.postAnalyze(
      mockReq({
        rawContent: 'https://example.com',
        client: { idUser: UID },
      }),
      reply,
    );

    expect(reply.statusCode).toBe(401);
    expect(publisher.published).toHaveLength(0);
  });

  it('não publica em 400', async () => {
    const publisher = new CapturingPublisher();
    const controller = new QrAnalyzeController({
      env,
      service: new QrAnalyzeService(),
      eventPublisher: publisher,
      userIdentity: new StubIdentity({ ok: true, idUser: UID }),
    });

    const reply = mockReply();
    await controller.postAnalyze(mockReq({ rawContent: '' }), reply);

    expect(reply.statusCode).toBe(400);
    expect(publisher.published).toHaveLength(0);
  });
});
