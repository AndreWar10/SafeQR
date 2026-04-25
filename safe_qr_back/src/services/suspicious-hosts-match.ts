/** Host em minúsculas, sem `www.` inicial. */
export function normalizeHostname(host: string): string {
  let h = host.toLowerCase().trim();
  if (h.startsWith('www.')) {
    h = h.slice(4);
  }
  return h;
}

/**
 * Extrai hostname normalizado a partir de uma entrada da lista (URL completa ou host).
 */
export function listEntryToNormalizedHost(entry: string): string | null {
  const t = entry.trim();
  if (!t) {
    return null;
  }
  try {
    const withScheme = t.includes('://') ? t : `https://${t}`;
    const u = new URL(withScheme);
    if (!u.hostname) {
      return null;
    }
    return normalizeHostname(u.hostname);
  } catch {
    return normalizeHostname(t);
  }
}

/** Correspondência exata ou subdomínio de um host da lista (ex.: `x.evil.com` vs `evil.com`). */
export function hostnameMatchesBlocklist(normalizedHost: string, blocklist: Set<string>): boolean {
  if (blocklist.has(normalizedHost)) {
    return true;
  }
  for (const blocked of blocklist) {
    if (!blocked) {
      continue;
    }
    if (normalizedHost.endsWith(`.${blocked}`)) {
      return true;
    }
  }
  return false;
}
