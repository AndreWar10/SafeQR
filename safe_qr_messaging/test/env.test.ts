import { describe, expect, it } from 'vitest';

import { loadEnv, resolveFirebaseKeyFilePath } from '../src/config/env.js';

describe('loadEnv', () => {
  it('habilita Firestore por padrão', () => {
    const env = loadEnv({
      GCP_PROJECT_ID: 'safe-qr-app',
    });

    expect(env.FIRESTORE_ENABLED).toBe(true);
    expect(env.FIRESTORE_COLLECTION).toBe('scan_events');
  });

  it('prioriza credencial Firebase dedicada', () => {
    const env = loadEnv({
      GCP_PROJECT_ID: 'safe-qr-app',
      GOOGLE_APPLICATION_CREDENTIALS: './credentials/pubsub.json',
      FIREBASE_GOOGLE_APPLICATION_CREDENTIALS: './credentials/firebase.json',
    });

    expect(resolveFirebaseKeyFilePath(env)).toBe('./credentials/firebase.json');
  });
});
