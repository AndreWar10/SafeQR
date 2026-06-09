import type { HistoryRepository, HistorySaveInput, HistorySaveResult } from './history-repository.port.js';

export class NullHistoryRepository implements HistoryRepository {
  async save(_input: HistorySaveInput): Promise<HistorySaveResult> {
    return 'skipped';
  }
}
