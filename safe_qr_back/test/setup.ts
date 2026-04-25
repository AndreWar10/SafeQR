import { loadEnv } from '../src/config/env.js';
import { createLogger } from '../src/lib/logger.js';
import { buildApp } from '../src/app.js';

export async function createTestApp() {
  const env = loadEnv({ ...process.env, NODE_ENV: 'test', LOG_LEVEL: 'silent' });
  const logger = createLogger(env);
  return buildApp(env, logger);
}
