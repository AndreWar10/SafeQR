import { z } from 'zod';

import { QrVerdict } from '../models/qr-verdict.js';

const verdictValues = [
  QrVerdict.safe,
  QrVerdict.suspicious,
  QrVerdict.unsafe,
  QrVerdict.unknown,
] as const;

export const historyItemSchema = z
  .object({
    id: z.string().uuid(),
    type: z.enum(['scan', 'generated']),
    content: z.string().min(1, 'content é obrigatório'),
    createdAtMs: z.number().int().positive(),
    verdict: z.enum(verdictValues).nullable(),
    safeToOpen: z.boolean().nullable(),
    reasons: z.array(z.string().max(500)).max(50),
  })
  .superRefine((item, ctx) => {
    if (item.type === 'scan') {
      if (item.verdict == null) {
        ctx.addIssue({ code: 'custom', message: 'verdict obrigatório para scan', path: ['verdict'] });
      }
      if (item.safeToOpen == null) {
        ctx.addIssue({
          code: 'custom',
          message: 'safeToOpen obrigatório para scan',
          path: ['safeToOpen'],
        });
      }
    }
    if (item.type === 'generated') {
      if (item.verdict != null || item.safeToOpen != null) {
        ctx.addIssue({
          code: 'custom',
          message: 'verdict/safeToOpen devem ser null para generated',
          path: ['verdict'],
        });
      }
    }
  });

export const historyPostBodySchema = z.object({
  item: historyItemSchema,
  client: z
    .object({
      appVersion: z.string().max(64).optional(),
      platform: z.string().max(32).optional(),
      idUser: z.string().min(1).max(128).optional(),
    })
    .optional(),
});

export const historyListQuerySchema = z.object({
  limit: z.coerce.number().int().positive().max(500).default(100),
  offset: z.coerce.number().int().nonnegative().default(0),
});

export const historyIdParamsSchema = z.object({
  id: z.string().uuid(),
});

export type HistoryPostBody = z.infer<typeof historyPostBodySchema>;
export type HistoryItemInput = z.infer<typeof historyItemSchema>;
export type HistoryListQuery = z.infer<typeof historyListQuerySchema>;
