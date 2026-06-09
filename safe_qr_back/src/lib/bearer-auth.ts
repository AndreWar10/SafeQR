import type { ResolveIdUserReason } from '../services/user-identity.port.js';

export function bearerAuthErrorMessage(reason: ResolveIdUserReason): string {
  switch (reason) {
    case 'missing':
      return 'Authorization: Bearer <Firebase ID Token> obrigatório.';
    case 'invalid_token':
      return 'Firebase ID Token inválido ou expirado. Obtenha um novo via getIdToken().';
    case 'auth_not_configured':
      return 'Servidor sem credenciais Firebase (GOOGLE_APPLICATION_CREDENTIALS).';
  }
}

export function bearerAuthStatusCode(reason: ResolveIdUserReason): 401 | 503 {
  return reason === 'auth_not_configured' ? 503 : 401;
}
