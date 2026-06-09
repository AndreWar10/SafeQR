import pino from 'pino';

import type { Env } from '../config/env.js';

export type Logger = pino.Logger;

export function createLogger(env: Env): Logger {
  const base = { service: 'safe-qr-messaging' };
  if (env.NODE_ENV === 'development') {
    return pino({
      level: env.LOG_LEVEL,
      base,
      transport: { target: 'pino-pretty', options: { colorize: true } },
    });
  }
  return pino({ level: env.LOG_LEVEL, base });
}
