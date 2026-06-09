import { FieldValue } from 'firebase-admin/firestore';

import type { HistoryItemPayload } from '../schemas/qr-analyzed.schema.js';

export type HistoryItemDocument = HistoryItemPayload & {
  idUser: string;
  savedAt: string;
  eventId: string;
  correlationId: string;
  consumedAt: FieldValue;
};

export function mapHistoryItemToDocument(
  idUser: string,
  eventId: string,
  correlationId: string,
  item: HistoryItemPayload,
): HistoryItemDocument {
  return {
    ...item,
    idUser,
    savedAt: new Date().toISOString(),
    eventId,
    correlationId,
    consumedAt: FieldValue.serverTimestamp(),
  };
}
