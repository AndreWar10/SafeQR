import { describe, expect, it } from 'vitest';

import {
  hostnameMatchesBlocklist,
  listEntryToNormalizedHost,
  normalizeHostname,
} from '../src/services/suspicious-hosts-match.js';

describe('suspicious-hosts-match', () => {
  it('normalizeHostname remove www', () => {
    expect(normalizeHostname('WWW.Example.COM')).toBe('example.com');
  });

  it('listEntryToNormalizedHost aceita URL completa', () => {
    expect(listEntryToNormalizedHost('https://amaz0n.com.br/x')).toBe('amaz0n.com.br');
  });

  it('hostnameMatchesBlocklist inclui subdomínio', () => {
    const s = new Set(['bad.com']);
    expect(hostnameMatchesBlocklist('pay.bad.com', s)).toBe(true);
    expect(hostnameMatchesBlocklist('bad.com', s)).toBe(true);
    expect(hostnameMatchesBlocklist('notbad.com', s)).toBe(false);
  });
});
