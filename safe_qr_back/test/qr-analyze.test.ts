import { describe, expect, it } from 'vitest';

import { loadEnv } from '../src/config/env.js';
import { createTestApp } from './setup.js';

describe('POST /v1/qr/analyze', () => {
  it('https simples → safe', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/qr/analyze',
      headers: { 'content-type': 'application/json' },
      payload: {
        rawContent: 'https://example.com/path',
        client: { appVersion: '1.0.0', platform: 'android' },
      },
    });
    expect(res.statusCode).toBe(200);
    const j = res.json() as {
      verdict: string;
      safeToOpen: boolean;
      requestId: string;
      parsed: { scheme?: string; host?: string };
    };
    expect(j.verdict).toBe('safe');
    expect(j.safeToOpen).toBe(true);
    expect(j.requestId).toMatch(/^[0-9a-f-]{36}$/i);
    expect(j.parsed.scheme).toBe('https');
    expect(j.parsed.host).toBe('example.com');
    await app.close();
  });

  it('bit.ly → suspicious', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/qr/analyze',
      headers: { 'content-type': 'application/json' },
      payload: { rawContent: 'https://bit.ly/abc123' },
    });
    expect(res.statusCode).toBe(200);
    const j = res.json() as { verdict: string; safeToOpen: boolean };
    expect(j.verdict).toBe('suspicious');
    expect(j.safeToOpen).toBe(false);
    await app.close();
  });

  it('javascript: → unsafe', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/qr/analyze',
      payload: { rawContent: 'javascript:alert(1)' },
    });
    expect(res.statusCode).toBe(200);
    const j = res.json() as { verdict: string };
    expect(j.verdict).toBe('unsafe');
    await app.close();
  });

  it('400 quando rawContent vazio', async () => {
    const app = await createTestApp();
    const res = await app.inject({
      method: 'POST',
      url: '/v1/qr/analyze',
      payload: { rawContent: '' },
    });
    expect(res.statusCode).toBe(400);
    await app.close();
  });

  it('413 quando payload excede limite', async () => {
    const env = loadEnv({
      ...process.env,
      NODE_ENV: 'test',
      LOG_LEVEL: 'fatal',
      MAX_RAW_CONTENT_BYTES: '10',
      GOOGLE_APPLICATION_CREDENTIALS: '',
      FIREBASE_SERVICE_ACCOUNT_JSON: '',
    });
    const { createLogger } = await import('../src/lib/logger.js');
    const { buildApp } = await import('../src/app.js');
    const tiny = await buildApp(env, createLogger(env));
    const res = await tiny.inject({
      method: 'POST',
      url: '/v1/qr/analyze',
      payload: { rawContent: 'x'.repeat(100) },
    });
    expect(res.statusCode).toBe(413);
    await tiny.close();
  });
});
