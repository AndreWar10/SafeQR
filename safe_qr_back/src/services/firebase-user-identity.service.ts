import { getAuth } from 'firebase-admin/auth';
import type { FastifyRequest } from 'fastify';

import { ensureFirebaseApp } from '../lib/firebase-admin.js';
import type { ResolveIdUserResult, UserIdentityPort } from './user-identity.port.js';

const TEST_BEARER_PREFIX = 'test:';

export type FirebaseUserIdentityConfig = {
  /** Apenas Vitest: `Authorization: Bearer test:<uid>`. */
  allowTestBearer: boolean;
  /** Credenciais Firebase configuradas — obrigatório para `verifyIdToken`. */
  verifyTokens: boolean;
};

/**
 * Autenticação via Firebase ID Token (JWT retornado por `getIdToken()` no cliente).
 * O UID do token (`decoded.uid`) é o dono do histórico — nunca confiar em `client.idUser`.
 */
export class FirebaseUserIdentityService implements UserIdentityPort {
  constructor(private readonly cfg: FirebaseUserIdentityConfig) {}

  async resolveBearerUid(req: FastifyRequest): Promise<ResolveIdUserResult> {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return { ok: false, reason: 'missing' };
    }

    const token = authHeader.slice(7).trim();
    if (!token) {
      return { ok: false, reason: 'invalid_token' };
    }

    if (this.cfg.allowTestBearer && token.startsWith(TEST_BEARER_PREFIX)) {
      const uid = token.slice(TEST_BEARER_PREFIX.length).trim();
      return uid ? { ok: true, idUser: uid } : { ok: false, reason: 'invalid_token' };
    }

    if (!this.cfg.verifyTokens) {
      return { ok: false, reason: 'auth_not_configured' };
    }

    try {
      ensureFirebaseApp();
      const decoded = await getAuth().verifyIdToken(token);
      if (!decoded.uid) {
        return { ok: false, reason: 'invalid_token' };
      }
      return { ok: true, idUser: decoded.uid };
    } catch (err) {
      console.warn(
        '[auth] verifyIdToken falhou:',
        err instanceof Error ? err.message : err,
      );
      return { ok: false, reason: 'invalid_token' };
    }
  }
}
