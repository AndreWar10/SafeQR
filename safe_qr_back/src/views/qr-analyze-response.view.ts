import type { QrAnalyzeResultModel } from '../models/analyze-result.model.js';

/** Formato JSON de saída (RF-B03) — camada View. */
export type QrAnalyzeResponseJson = {
  requestId: string;
  verdict: string;
  safeToOpen: boolean;
  reasons: string[];
  parsed: Record<string, string | undefined>;
};

export function toQrAnalyzeResponseJson(model: QrAnalyzeResultModel): QrAnalyzeResponseJson {
  const p = model.parsed;
  return {
    requestId: model.requestId,
    verdict: model.verdict,
    safeToOpen: model.safeToOpen,
    reasons: model.reasons,
    parsed: {
      ...(p.type !== undefined ? { type: p.type } : {}),
      ...(p.scheme !== undefined ? { scheme: p.scheme } : {}),
      ...(p.host !== undefined ? { host: p.host } : {}),
    },
  };
}
