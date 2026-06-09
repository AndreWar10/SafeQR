import type { HistoryItemModel, HistoryListResult, HistoryUpsertResult } from '../models/history-item.model.js';

export type HistoryListOptions = {
  limit: number;
  offset: number;
};

export interface HistoryRepositoryPort {
  upsert(idUser: string, item: HistoryItemModel): Promise<HistoryUpsertResult>;
  list(idUser: string, options: HistoryListOptions): Promise<HistoryListResult>;
  deleteById(idUser: string, id: string): Promise<boolean>;
  clear(idUser: string): Promise<void>;
}
