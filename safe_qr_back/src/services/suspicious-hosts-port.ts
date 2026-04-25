/**
 * Lista de hosts suspeitos (ex.: clones) — implementação remota opcional (Firestore).
 */
export interface SuspiciousHostsPort {
  /** Host do URL já normalizado (minúsculas, sem `www.`). */
  isListedHostname(normalizedHost: string): Promise<boolean>;
}

/** Sem credenciais Firestore ou desativado: nunca lista. */
export class NullSuspiciousHostsPort implements SuspiciousHostsPort {
  async isListedHostname(): Promise<boolean> {
    return false;
  }
}
