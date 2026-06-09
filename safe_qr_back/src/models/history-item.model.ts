import type { QrVerdictName } from './qr-verdict.js';

export const HistoryItemType = {
  scan: 'scan',
  generated: 'generated',
} as const;

export type HistoryItemTypeName = (typeof HistoryItemType)[keyof typeof HistoryItemType];

/** Item de histórico — espelho do SQLite mobile (`HistoryItem`). */
export type HistoryItemModel = {
  id: string;
  type: HistoryItemTypeName;
  content: string;
  createdAtMs: number;
  verdict: QrVerdictName | null;
  safeToOpen: boolean | null;
  reasons: string[];
};

/** Registro persistido (inclui metadados do servidor). */
export type HistoryItemRecord = HistoryItemModel & {
  idUser: string;
  savedAt: string;
};

export type HistoryUpsertResult = {
  id: string;
  idUser: string;
  savedAt: string;
};

export type HistoryListResult = {
  items: HistoryItemModel[];
  total: number;
};
