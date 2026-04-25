import { z } from 'zod';

/** Corpo de entrada — alinhado ao doc Sprint 1 e ao app Flutter. */
export const qrAnalyzeBodySchema = z.object({
  rawContent: z.string().min(1, 'rawContent é obrigatório').max(200_000),
  client: z
    .object({
      appVersion: z.string().max(64).optional(),
      platform: z.string().max(32).optional(),
    })
    .optional(),
});

export type QrAnalyzeBody = z.infer<typeof qrAnalyzeBodySchema>;
