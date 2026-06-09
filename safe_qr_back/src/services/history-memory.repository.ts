import type { HistoryItemModel, HistoryItemRecord, HistoryUpsertResult } from '../models/history-item.model.js';
import type { HistoryListOptions, HistoryRepositoryPort } from './history-repository.port.js';

/**
 * Repositório em memória — testes e dev sem credenciais Firebase.
 * Chave composta: (idUser, id).
 */
export class InMemoryHistoryRepository implements HistoryRepositoryPort {
  private readonly store = new Map<string, Map<string, HistoryItemRecord>>();

  async upsert(idUser: string, item: HistoryItemModel): Promise<HistoryUpsertResult> {
    const savedAt = new Date().toISOString();
    const record: HistoryItemRecord = { ...item, idUser, savedAt };
    let userMap = this.store.get(idUser);
    if (!userMap) {
      userMap = new Map();
      this.store.set(idUser, userMap);
    }
    userMap.set(item.id, record);
    return { id: item.id, idUser, savedAt };
  }

  async list(idUser: string, options: HistoryListOptions) {
    const userMap = this.store.get(idUser);
    const all = userMap
      ? [...userMap.values()].sort((a, b) => b.createdAtMs - a.createdAtMs)
      : [];
    const items = all.slice(options.offset, options.offset + options.limit).map(toItemModel);
    return { items, total: all.length };
  }

  async deleteById(idUser: string, id: string): Promise<boolean> {
    const userMap = this.store.get(idUser);
    if (!userMap?.has(id)) {
      return false;
    }
    userMap.delete(id);
    return true;
  }

  async clear(idUser: string): Promise<void> {
    this.store.delete(idUser);
  }
}

function toItemModel(record: HistoryItemRecord): HistoryItemModel {
  return {
    id: record.id,
    type: record.type,
    content: record.content,
    createdAtMs: record.createdAtMs,
    verdict: record.verdict,
    safeToOpen: record.safeToOpen,
    reasons: record.reasons,
  };
}
