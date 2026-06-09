import { describe, expect, it } from 'vitest';

import { createTestApp } from './setup.js';

const USER_A = 'K7xY2zQ1aBcDeFgHiJkLmNoPqRs';
const USER_B = 'OtherUserUid123456789012345';

const SCAN_ID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
const GEN_ID = 'b2c3d4e5-f6a7-8901-bcde-f12345678901';
const MISSING_ID = 'c3d4e5f6-a7b8-9012-cdef-123456789012';

function authHeader(uid: string) {
  return { authorization: `Bearer test:${uid}` };
}

function scanPayload(overrides: Record<string, unknown> = {}) {
  return {
    item: {
      id: SCAN_ID,
      type: 'scan',
      content: 'https://example.com/path',
      createdAtMs: 1717689600123,
      verdict: 'suspicious',
      safeToOpen: false,
      reasons: ['URL usa redirecionador conhecido (destino não visível diretamente).'],
      ...overrides,
    },
    client: {
      appVersion: '1.0.0',
      platform: 'android',
      idUser: USER_A,
    },
  };
}

function generatedPayload() {
  return {
    item: {
      id: GEN_ID,
      type: 'generated',
      content: 'WIFI:T:WPA;S:MinhaRede;P:senha123;;',
      createdAtMs: 1717689700456,
      verdict: null,
      safeToOpen: null,
      reasons: ['Tipo: wifi'],
    },
    client: {
      appVersion: '1.0.0',
      platform: 'android',
      idUser: USER_A,
    },
  };
}

describe('POST /v1/history', () => {
  it('cria item scan com Bearer → 201', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload(),
    });
    expect(res.statusCode).toBe(201);
    const body = res.json() as { id: string; idUser: string; savedAt: string };
    expect(body.id).toBe(SCAN_ID);
    expect(body.idUser).toBe(USER_A);
    expect(body.savedAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
    await app.close();
  });

  it('cria item generated → 201', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: generatedPayload(),
    });
    expect(res.statusCode).toBe(201);
    await app.close();
  });

  it('upsert por id substitui conteúdo', async () => {
    const app = await createTestApp();
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload(),
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload({ content: 'https://updated.example.com' }),
    });
    expect(res.statusCode).toBe(201);

    const list = await app.inject({
      method: 'GET',
      url: '/v1/history',
      headers: authHeader(USER_A),
    });
    const items = (list.json() as { items: { content: string }[] }).items;
    expect(items[0]?.content).toBe('https://updated.example.com');
    await app.close();
  });

  it('400 quando scan sem verdict', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload({ verdict: null, safeToOpen: null }),
    });
    expect(res.statusCode).toBe(400);
    await app.close();
  });

  it('400 quando generated com verdict', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: {
        item: {
          ...generatedPayload().item,
          verdict: 'safe',
          safeToOpen: true,
        },
      },
    });
    expect(res.statusCode).toBe(400);
    await app.close();
  });

  it('413 quando content > 2000 chars', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload({ content: 'x'.repeat(2001) }),
    });
    expect(res.statusCode).toBe(413);
    await app.close();
  });

  it('401 sem Bearer token', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/history',
      payload: { item: scanPayload().item },
    });
    expect(res.statusCode).toBe(401);
    await app.close();
  });

  it('rejeita Bearer com UID em vez de JWT (sem prefixo test:)', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'GET',
      url: '/v1/history',
      headers: { authorization: `Bearer ${USER_A}` },
    });
    // Sem credenciais Firebase no CI de teste → 503; com credenciais → 401
    expect([401, 503]).toContain(res.statusCode);
    await app.close();
  });
});

describe('GET /v1/history', () => {
  it('lista itens mais recente primeiro', async () => {
    const app = await createTestApp();
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload({ createdAtMs: 1000 }),
    });
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: generatedPayload(),
    });

    const res = await app.inject({
      method: 'GET',
      url: '/v1/history',
      headers: authHeader(USER_A),
    });
    expect(res.statusCode).toBe(200);
    const body = res.json() as {
      items: { type: string; createdAtMs: number }[];
      total: number;
    };
    expect(body.total).toBe(2);
    expect(body.items[0]?.createdAtMs).toBeGreaterThan(body.items[1]?.createdAtMs ?? 0);
    await app.close();
  });

  it('respeita limit e offset', async () => {
    const app = await createTestApp();
    for (let i = 0; i < 3; i++) {
      await app.inject({
        method: 'POST',
        url: '/v1/history',
        headers: authHeader(USER_A),
        payload: scanPayload({
          id: `d4e5f6a7-b8c9-4012-d345-${String(i).padStart(12, '0')}`,
          createdAtMs: 1000 + i,
        }),
      });
    }

    const res = await app.inject({
      method: 'GET',
      url: '/v1/history?limit=1&offset=1',
      headers: authHeader(USER_A),
    });
    const body = res.json() as { items: unknown[]; total: number };
    expect(body.items).toHaveLength(1);
    expect(body.total).toBe(3);
    await app.close();
  });

  it('401 sem autenticação', async () => {
    const app = await createTestApp();
    const res = await app.inject({ method: 'GET', url: '/v1/history' });
    expect(res.statusCode).toBe(401);
    await app.close();
  });
});

describe('DELETE /v1/history/:id', () => {
  it('apaga item do utilizador → 204', async () => {
    const app = await createTestApp();
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload(),
    });

    const res = await app.inject({
      method: 'DELETE',
      url: `/v1/history/${SCAN_ID}`,
      headers: authHeader(USER_A),
    });
    expect(res.statusCode).toBe(204);

    const list = await app.inject({
      method: 'GET',
      url: '/v1/history',
      headers: authHeader(USER_A),
    });
    expect((list.json() as { total: number }).total).toBe(0);
    await app.close();
  });

  it('404 quando item não existe', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'DELETE',
      url: `/v1/history/${MISSING_ID}`,
      headers: authHeader(USER_A),
    });
    expect(res.statusCode).toBe(404);
    await app.close();
  });

  it('404 quando item pertence a outro utilizador', async () => {
    const app = await createTestApp();
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload(),
    });

    const res = await app.inject({
      method: 'DELETE',
      url: `/v1/history/${SCAN_ID}`,
      headers: authHeader(USER_B),
    });
    expect(res.statusCode).toBe(404);
    await app.close();
  });
});

describe('DELETE /v1/history', () => {
  it('limpa todo o histórico do utilizador → 204', async () => {
    const app = await createTestApp();
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: scanPayload(),
    });
    await app.inject({
      method: 'POST',
      url: '/v1/history',
      headers: authHeader(USER_A),
      payload: generatedPayload(),
    });

    const res = await app.inject({
      method: 'DELETE',
      url: '/v1/history',
      headers: authHeader(USER_A),
    });
    expect(res.statusCode).toBe(204);

    const list = await app.inject({
      method: 'GET',
      url: '/v1/history',
      headers: authHeader(USER_A),
    });
    expect((list.json() as { total: number }).total).toBe(0);
    await app.close();
  });
});
