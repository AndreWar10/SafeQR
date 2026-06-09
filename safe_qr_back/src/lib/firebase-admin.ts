import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import type { ServiceAccount } from 'firebase-admin/app';

/** Inicializa o Firebase Admin SDK uma única vez (Firestore, Auth, etc.). */
export function ensureFirebaseApp(): void {
  if (getApps().length > 0) {
    return;
  }
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (rawJson) {
    const parsed = JSON.parse(rawJson) as ServiceAccount;
    initializeApp({ credential: cert(parsed) });
    return;
  }
  initializeApp({ credential: applicationDefault() });
}

export function hasFirebaseCredentials(env: {
  GOOGLE_APPLICATION_CREDENTIALS?: string;
  FIREBASE_SERVICE_ACCOUNT_JSON?: string;
}): boolean {
  return Boolean(env.GOOGLE_APPLICATION_CREDENTIALS?.trim() || env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim());
}
