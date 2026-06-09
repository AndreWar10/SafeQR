import { describe, expect, it } from 'vitest';

import {
  loadEnv,
  resolveAuditSubscription,
  resolveFirebaseKeyFilePath,
  resolveHistorySubscription,
} from '../src/config/env.js';

describe('loadEnv', () => {
  it('habilita Firestore por padrão', () => {
    const env = loadEnv({
      GCP_PROJECT_ID: 'safe-qr-app',
    });

    expect(env.FIRESTORE_ENABLED).toBe(true);
    expect(env.FIRESTORE_COLLECTION).toBe('scan_events');
    expect(env.FIRESTORE_HISTORY_COLLECTION).toBe('history');
  });

  it('prioriza credencial Firebase dedicada', () => {
    const env = loadEnv({
      GCP_PROJECT_ID: 'safe-qr-app',
      GOOGLE_APPLICATION_CREDENTIALS: './credentials/pubsub.json',
      FIREBASE_GOOGLE_APPLICATION_CREDENTIALS: './credentials/firebase.json',
    });

    expect(resolveFirebaseKeyFilePath(env)).toBe('./credentials/firebase.json');
  });

  it('resolve subscriptions de audit e history', () => {
    const env = loadEnv({
      GCP_PROJECT_ID: 'safe-qr-app',
      PUBSUB_SUBSCRIPTION: 'safe-qr-analyze-events-sub',
      PUBSUB_SUBSCRIPTION_HISTORY: 'safe-qr-analyze-events-sub-history',
    });

    expect(resolveAuditSubscription(env)).toBe('safe-qr-analyze-events-sub');
    expect(resolveHistorySubscription(env)).toBe('safe-qr-analyze-events-sub-history');
  });
});
