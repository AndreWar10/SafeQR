import { describe, expect, it } from 'vitest';

import { createTestApp } from './setup.js';

describe('GET /v1/health', () => {
  it('retorna 200 e status ok', async () => {
    const app = await createTestApp();
    const res = await app.inject({ method: 'GET', url: '/v1/health' });
    expect(res.statusCode).toBe(200);
    const body = res.json() as { status: string; service: string };
    expect(body.status).toBe('ok');
    expect(body.service).toBe('safe-qr-api');
    await app.close();
  });
});

describe('GET /health', () => {
  it('alias de health', async () => {
    const app = await createTestApp();
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    await app.close();
  });
});
