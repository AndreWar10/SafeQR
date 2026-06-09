import type { HistoryItemModel, HistoryListResult, HistoryUpsertResult } from '../models/history-item.model.js';
import type { HistoryListOptions, HistoryRepositoryPort } from './history-repository.port.js';

export class HistoryService {
  constructor(private readonly repository: HistoryRepositoryPort) {}

  upsert(idUser: string, item: HistoryItemModel): Promise<HistoryUpsertResult> {
    return this.repository.upsert(idUser, item);
  }

  list(idUser: string, options: HistoryListOptions): Promise<HistoryListResult> {
    return this.repository.list(idUser, options);
  }

  deleteById(idUser: string, id: string): Promise<boolean> {
    return this.repository.deleteById(idUser, id);
  }

  clear(idUser: string): Promise<void> {
    return this.repository.clear(idUser);
  }
}
