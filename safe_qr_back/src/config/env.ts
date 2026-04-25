import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  MAX_RAW_CONTENT_BYTES: z.coerce.number().int().positive().max(1024 * 1024).default(8192),
  /** Caminho absoluto ou relativo ao JSON da conta de serviço (Admin SDK). */
  GOOGLE_APPLICATION_CREDENTIALS: z.string().optional(),
  /** Alternativa ao ficheiro: JSON inline (ex.: CI / PaaS). */
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().optional(),
  /** TTL do cache em memória da lista `suspicious_hosts/clones`. */
  FIRESTORE_SUSPICIOUS_CACHE_MS: z.coerce.number().int().positive().max(3_600_000).default(60_000),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(processEnv: NodeJS.ProcessEnv = process.env): Env {
  const parsed = envSchema.safeParse(processEnv);
  if (!parsed.success) {
    const msg = parsed.error.flatten().fieldErrors;
    throw new Error(`Invalid environment: ${JSON.stringify(msg)}`);
  }
  return parsed.data;
}
