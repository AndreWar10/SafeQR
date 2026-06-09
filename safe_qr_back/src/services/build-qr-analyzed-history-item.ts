import type { QrAnalyzeResultModel } from '../models/analyze-result.model.js';

const MAX_HISTORY_CONTENT_CHARS = 2000;

export type QrAnalyzedHistoryItem = {
  id: string;
  type: 'scan';
  content: string;
  createdAtMs: number;
  verdict: QrAnalyzeResultModel['verdict'];
  safeToOpen: boolean;
  reasons: string[];
};

export function clipHistoryContent(rawContent: string, max = MAX_HISTORY_CONTENT_CHARS): string {
  const trimmed = rawContent.trim();
  if (trimmed.length <= max) {
    return trimmed;
  }
  return trimmed.slice(0, max);
}

export function buildQrAnalyzedHistoryItem(
  historyItemId: string,
  rawContent: string,
  model: QrAnalyzeResultModel,
  createdAtMs = Date.now(),
): QrAnalyzedHistoryItem {
  return {
    id: historyItemId,
    type: 'scan',
    content: clipHistoryContent(rawContent),
    createdAtMs,
    verdict: model.verdict,
    safeToOpen: model.safeToOpen,
    reasons: model.reasons,
  };
}
