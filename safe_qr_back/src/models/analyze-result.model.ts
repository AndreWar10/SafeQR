import type { QrVerdictName } from './qr-verdict.js';

export type QrParsedSummary = {
  type?: string;
  scheme?: string;
  host?: string;
};

/** Resultado de domínio produzido pelo serviço de análise (camada Model). */
export type QrAnalyzeResultModel = {
  requestId: string;
  verdict: QrVerdictName;
  safeToOpen: boolean;
  reasons: string[];
  parsed: QrParsedSummary;
};
