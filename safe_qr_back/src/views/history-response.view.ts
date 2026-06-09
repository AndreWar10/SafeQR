import type { HistoryItemModel, HistoryListResult, HistoryUpsertResult } from '../models/history-item.model.js';

export type HistoryUpsertResponseJson = {
  id: string;
  idUser: string;
  savedAt: string;
};

export type HistoryListResponseJson = {
  items: HistoryItemModel[];
  total: number;
};

export function toHistoryUpsertResponseJson(result: HistoryUpsertResult): HistoryUpsertResponseJson {
  return {
    id: result.id,
    idUser: result.idUser,
    savedAt: result.savedAt,
  };
}

export function toHistoryListResponseJson(result: HistoryListResult): HistoryListResponseJson {
  return {
    items: result.items,
    total: result.total,
  };
}
