import type { FastifyRequest } from 'fastify';

export type ResolveIdUserReason = 'missing' | 'invalid_token' | 'auth_not_configured';

export type ResolveIdUserResult =
  | { ok: true; idUser: string }
  | { ok: false; reason: ResolveIdUserReason };

export interface UserIdentityPort {
  /** Valida `Authorization: Bearer <Firebase ID Token>` e devolve `decoded.uid`. */
  resolveBearerUid(req: FastifyRequest): Promise<ResolveIdUserResult>;
}
