import { getFirestore } from 'firebase-admin/firestore';

import { resolveFirebaseKeyFilePath, type Env } from '../config/env.js';
import { ensureFirebaseApp } from '../lib/firebase-app.js';
import { isAlreadyExistsError, isPermissionDeniedError } from '../lib/firestore-errors.js';
import type { Logger } from '../lib/logger.js';
import { mapHistoryItemToDocument } from '../mappers/history-item-document.mapper.js';
import type { HistoryRepository, HistorySaveInput, HistorySaveResult } from './history-repository.port.js';

export class FirestoreHistoryRepository implements HistoryRepository {
  private initialized = false;

  constructor(
    private readonly env: Env,
    private readonly logger: Logger,
  ) {}

  async save(input: HistorySaveInput): Promise<HistorySaveResult> {
    this.ensureReady();

    const docRef = getFirestore()
      .collection(this.env.FIRESTORE_HISTORY_COLLECTION)
      .doc(input.idUser)
      .collection(this.env.FIRESTORE_HISTORY_ITEMS_SUBCOLLECTION)
      .doc(input.item.id);

    const payload = mapHistoryItemToDocument(
      input.idUser,
      input.eventId,
      input.correlationId,
      input.item,
    );

    try {
      await docRef.create(payload);
      return 'created';
    } catch (err) {
      if (isAlreadyExistsError(err)) {
        this.logger.debug(
          { eventId: input.eventId, historyItemId: input.item.id },
          'Item de histórico já persistido',
        );
        return 'exists';
      }
      if (isPermissionDeniedError(err)) {
        this.logger.error(
          {
            eventId: input.eventId,
            idUser: input.idUser,
            hint: 'A SA em FIREBASE_GOOGLE_APPLICATION_CREDENTIALS precisa da role Cloud Datastore User (roles/datastore.user)',
          },
          'Firestore PERMISSION_DENIED ao gravar history',
        );
      }
      throw err;
    }
  }

  private ensureReady(): void {
    if (this.initialized) {
      return;
    }

    ensureFirebaseApp({
      keyFilePath: resolveFirebaseKeyFilePath(this.env),
      serviceAccountJson: this.env.FIREBASE_SERVICE_ACCOUNT_JSON,
    });
    this.initialized = true;
  }
}
