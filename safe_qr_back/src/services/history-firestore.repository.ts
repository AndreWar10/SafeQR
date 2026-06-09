import { getFirestore } from 'firebase-admin/firestore';

import { ensureFirebaseApp } from '../lib/firebase-admin.js';
import type { HistoryItemModel, HistoryItemRecord, HistoryUpsertResult } from '../models/history-item.model.js';
import type { HistoryListOptions, HistoryRepositoryPort } from './history-repository.port.js';

const USER_COLLECTION = 'history';
const ITEMS_SUBCOLLECTION = 'items';

/**
 * Firestore: `history/{idUser}/items/{id}` — chave composta (idUser, id).
 * Índice implícito: orderBy `createdAtMs` DESC por subcoleção do utilizador.
 */
export class FirestoreHistoryRepository implements HistoryRepositoryPort {
  private db() {
    ensureFirebaseApp();
    return getFirestore();
  }

  private itemRef(idUser: string, id: string) {
    return this.db().collection(USER_COLLECTION).doc(idUser).collection(ITEMS_SUBCOLLECTION).doc(id);
  }

  private itemsCollection(idUser: string) {
    return this.db().collection(USER_COLLECTION).doc(idUser).collection(ITEMS_SUBCOLLECTION);
  }

  async upsert(idUser: string, item: HistoryItemModel): Promise<HistoryUpsertResult> {
    const savedAt = new Date().toISOString();
    const record: HistoryItemRecord = { ...item, idUser, savedAt };
    await this.itemRef(idUser, item.id).set(record);
    return { id: item.id, idUser, savedAt };
  }

  async list(idUser: string, options: HistoryListOptions) {
    const col = this.itemsCollection(idUser);
    const countSnap = await col.count().get();
    const total = countSnap.data().count;

    const snap = await col.orderBy('createdAtMs', 'desc').offset(options.offset).limit(options.limit).get();

    const items = snap.docs.map((doc) => {
      const data = doc.data() as HistoryItemRecord;
      // O ID do documento Firestore é a chave usada no DELETE — não confiar só no campo `id` gravado.
      return toItemModel({ ...data, id: doc.id });
    });
    return { items, total };
  }

  async deleteById(idUser: string, id: string): Promise<boolean> {
    const ref = this.itemRef(idUser, id);
    const snap = await ref.get();
    if (!snap.exists) {
      return false;
    }
    try {
      await ref.delete();
      return true;
    } catch (err) {
      const code = (err as { code?: number | string }).code;
      throw new Error(
        `Firestore delete falhou history/${idUser}/items/${id}${code != null ? ` (code=${code})` : ''}`,
        { cause: err },
      );
    }
  }

  async clear(idUser: string): Promise<void> {
    const col = this.itemsCollection(idUser);
    const batchSize = 200;
    let hasMore = true;
    while (hasMore) {
      const snap = await col.limit(batchSize).get();
      if (snap.empty) {
        break;
      }
      const batch = this.db().batch();
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      hasMore = snap.size >= batchSize;
    }
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
