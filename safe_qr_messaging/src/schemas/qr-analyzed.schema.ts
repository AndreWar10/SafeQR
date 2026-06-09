import { z } from 'zod';

export const historyItemSchema = z.object({
  id: z.string().uuid(),
  type: z.literal('scan'),
  content: z.string().min(1).max(2000),
  createdAtMs: z.number().int().positive(),
  verdict: z.enum(['safe', 'suspicious', 'unsafe', 'unknown']),
  safeToOpen: z.boolean(),
  reasons: z.array(z.string().max(500)).max(50),
});

export const qrAnalyzedDataSchema = z.object({
  idUser: z.string().max(128).nullable(),
  contentDigest: z.string().min(1).max(128),
  rawByteLength: z.number().int().nonnegative(),
  verdict: z.enum(['safe', 'suspicious', 'unsafe', 'unknown']),
  safeToOpen: z.boolean(),
  reasonCodes: z.array(z.string()),
  reasonsCount: z.number().int().nonnegative(),
  parsed: z
    .object({
      type: z.string().optional(),
      scheme: z.string().optional(),
      host: z.string().optional(),
    })
    .optional()
    .default({}),
  client: z
    .object({
      platform: z.string().optional(),
      appVersion: z.string().optional(),
    })
    .optional(),
  analysisDurationMs: z.number().int().nonnegative(),
  historyItem: historyItemSchema.optional(),
});

export const qrAnalyzedEnvelopeSchema = z.object({
  schemaVersion: z.literal('1'),
  eventId: z.string().uuid(),
  eventType: z.literal('qr.analyzed'),
  occurredAt: z.string().datetime(),
  source: z.literal('safe-qr-api'),
  correlationId: z.string().min(1),
  data: qrAnalyzedDataSchema,
});

export type HistoryItemPayload = z.infer<typeof historyItemSchema>;
export type QrAnalyzedEnvelope = z.infer<typeof qrAnalyzedEnvelopeSchema>;
