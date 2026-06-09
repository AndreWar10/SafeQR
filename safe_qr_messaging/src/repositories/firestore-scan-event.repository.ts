import { getFirestore } from 'firebase-admin/firestore';

import { resolveFirebaseKeyFilePath, type Env } from '../config/env.js';
import { ensureFirebaseApp } from '../lib/firebase-app.js';
import type { Logger } from '../lib/logger.js';
import { mapEnvelopeToScanEventDocument } from '../mappers/scan-event-document.mapper.js';
import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';
import type { ScanEventRepository, ScanEventSaveResult } from './scan-event-repository.port.js';

const ALREADY_EXISTS_CODE = 6;

const PERMISSION_DENIED_CODE = 7;

function isAlreadyExistsError(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code: number }).code === ALREADY_EXISTS_CODE
  );
}

function isPermissionDeniedError(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    'code' in err &&
    (err as { code: number }).code === PERMISSION_DENIED_CODE
  );
}

export class FirestoreScanEventRepository implements ScanEventRepository {
  private initialized = false;

  constructor(
    private readonly env: Env,
    private readonly logger: Logger,
  ) {}

  async save(envelope: QrAnalyzedEnvelope): Promise<ScanEventSaveResult> {
    this.ensureReady();

    const docRef = getFirestore().collection(this.env.FIRESTORE_COLLECTION).doc(envelope.eventId);
    const payload = mapEnvelopeToScanEventDocument(envelope);

    try {
      await docRef.create(payload);
      return 'created';
    } catch (err) {
      if (isAlreadyExistsError(err)) {
        this.logger.debug({ eventId: envelope.eventId }, 'Evento já persistido no Firestore');
        return 'exists';
      }
      if (isPermissionDeniedError(err)) {
        this.logger.error(
          {
            eventId: envelope.eventId,
            hint: 'A SA em FIREBASE_GOOGLE_APPLICATION_CREDENTIALS precisa da role Cloud Datastore User (roles/datastore.user)',
          },
          'Firestore PERMISSION_DENIED ao gravar scan_events',
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
