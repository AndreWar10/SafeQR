import { z } from 'zod';

const boolFromEnv = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  GCP_PROJECT_ID: z.string().min(1),
  GOOGLE_APPLICATION_CREDENTIALS: z.string().optional(),
  PUBSUB_SUBSCRIPTION: z.string().default('safe-qr-analyze-events-sub'),
  PUBSUB_SUBSCRIPTION_AUDIT: z.string().optional(),
  PUBSUB_SUBSCRIPTION_HISTORY: z.string().optional(),
  CONSUMER_ENABLED: boolFromEnv.default('true'),
  CONSUMER_MAX_MESSAGES: z.coerce.number().int().positive().max(100).default(10),
  CONSUMER_ACK_DEADLINE_SEC: z.coerce.number().int().positive().max(600).default(60),
  FIRESTORE_ENABLED: boolFromEnv.default('true'),
  FIRESTORE_COLLECTION: z.string().min(1).default('scan_events'),
  FIRESTORE_HISTORY_COLLECTION: z.string().min(1).default('history'),
  FIRESTORE_HISTORY_ITEMS_SUBCOLLECTION: z.string().min(1).default('items'),
  FIREBASE_GOOGLE_APPLICATION_CREDENTIALS: z.string().optional(),
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(processEnv: NodeJS.ProcessEnv = process.env): Env {
  const parsed = envSchema.safeParse(processEnv);
  if (!parsed.success) {
    throw new Error(`Invalid environment: ${JSON.stringify(parsed.error.flatten().fieldErrors)}`);
  }
  return parsed.data;
}

export function resolveFirebaseKeyFilePath(env: Env): string | undefined {
  const firebasePath = env.FIREBASE_GOOGLE_APPLICATION_CREDENTIALS?.trim();
  if (firebasePath) {
    return firebasePath;
  }
  return env.GOOGLE_APPLICATION_CREDENTIALS?.trim() || undefined;
}

export function resolveAuditSubscription(env: Env): string {
  return env.PUBSUB_SUBSCRIPTION_AUDIT?.trim() || env.PUBSUB_SUBSCRIPTION;
}

export function resolveHistorySubscription(env: Env): string {
  return env.PUBSUB_SUBSCRIPTION_HISTORY?.trim() || 'safe-qr-analyze-events-sub-history';
}
