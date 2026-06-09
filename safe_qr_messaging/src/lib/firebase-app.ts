import { readFileSync } from 'node:fs';

import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import type { ServiceAccount } from 'firebase-admin/app';

export type FirebaseCredentialConfig = {
  keyFilePath?: string;
  serviceAccountJson?: string;
};

export function ensureFirebaseApp(config: FirebaseCredentialConfig): void {
  if (getApps().length > 0) {
    return;
  }

  const rawJson = config.serviceAccountJson?.trim();
  if (rawJson) {
    const parsed = JSON.parse(rawJson) as ServiceAccount;
    initializeApp({ credential: cert(parsed) });
    return;
  }

  const keyFile = config.keyFilePath?.trim();
  if (keyFile) {
    const parsed = JSON.parse(readFileSync(keyFile, 'utf8')) as ServiceAccount;
    initializeApp({ credential: cert(parsed) });
    return;
  }

  initializeApp({ credential: applicationDefault() });
}
