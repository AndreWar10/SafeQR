import type { HistoryItemPayload } from '../schemas/qr-analyzed.schema.js';

export type HistorySaveResult = 'created' | 'exists' | 'skipped';

export type HistorySaveInput = {
  idUser: string;
  eventId: string;
  correlationId: string;
  item: HistoryItemPayload;
};

export interface HistoryRepository {
  save(input: HistorySaveInput): Promise<HistorySaveResult>;
}
