import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import type { ServiceAccount } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import type { SuspiciousHostsPort } from './suspicious-hosts-port.js';
import { hostnameMatchesBlocklist, listEntryToNormalizedHost, normalizeHostname } from './suspicious-hosts-match.js';

const DOC_PATH = 'suspicious_hosts/clones';

export type FirestoreSuspiciousHostsConfig = {
  cacheTtlMs: number;
};

/**
 * Lê o documento Firestore `suspicious_hosts/clones`, campo `urls` (array de strings),
 * e expõe consulta por hostname normalizado (com cache em memória).
 */
export class FirestoreSuspiciousHostsPort implements SuspiciousHostsPort {
  private cache: { hosts: Set<string>; fetchedAt: number } | null = null;

  constructor(private readonly cfg: FirestoreSuspiciousHostsConfig) {}

  async isListedHostname(normalizedHost: string): Promise<boolean> {
    const host = normalizeHostname(normalizedHost);
    if (!host) {
      return false;
    }
    try {
      const set = await this.loadBlocklist();
      return hostnameMatchesBlocklist(host, set);
    } catch (err) {
      // Fail-open: não bloquear análise se Firestore falhar (rede, regras, credencial).
      console.warn('[suspicious_hosts] Firestore indisponível; ignorando lista.', err);
      return false;
    }
  }

  private ensureFirebaseApp(): void {
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

  private async loadBlocklist(): Promise<Set<string>> {
    const now = Date.now();
    if (this.cache && now - this.cache.fetchedAt < this.cfg.cacheTtlMs) {
      return this.cache.hosts;
    }

    this.ensureFirebaseApp();
    const db = getFirestore();
    const snap = await db.doc(DOC_PATH).get();
    if (!snap.exists) {
      this.cache = { hosts: new Set(), fetchedAt: now };
      return this.cache.hosts;
    }

    const data = snap.data() as Record<string, unknown> | undefined;
    const urls = data?.urls;
    const hosts = new Set<string>();
    if (Array.isArray(urls)) {
      for (const item of urls) {
        if (typeof item !== 'string') {
          continue;
        }
        const h = listEntryToNormalizedHost(item);
        if (h) {
          hosts.add(h);
        }
      }
    }

    this.cache = { hosts, fetchedAt: now };
    return hosts;
  }
}
