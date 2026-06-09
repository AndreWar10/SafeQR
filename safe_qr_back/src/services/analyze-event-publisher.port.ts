import type { QrAnalyzeResultModel } from '../models/analyze-result.model.js';

export type QrAnalyzedPublishInput = {
  correlationId: string;
  idUser: string | null;
  contentDigest: string;
  rawByteLength: number;
  model: QrAnalyzeResultModel;
  reasonCodes: string[];
  client?: { platform?: string; appVersion?: string; idUser?: string };
  analysisDurationMs: number;
};

export interface AnalyzeEventPublisherPort {
  publishQrAnalyzed(input: QrAnalyzedPublishInput): Promise<void>;
}
