/** Alinhado ao contrato mobile (`verdict` em camelCase). */
export const QrVerdict = {
  safe: 'safe',
  suspicious: 'suspicious',
  unsafe: 'unsafe',
  unknown: 'unknown',
} as const;

export type QrVerdictName = (typeof QrVerdict)[keyof typeof QrVerdict];
