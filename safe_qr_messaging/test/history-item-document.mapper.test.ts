import { describe, expect, it } from 'vitest';

import { mapHistoryItemToDocument } from '../src/mappers/history-item-document.mapper.js';
import { historyItemSchema } from '../src/schemas/qr-analyzed.schema.js';

describe('mapHistoryItemToDocument', () => {
  it('mapeia item para documento Firestore', () => {
    const item = historyItemSchema.parse({
      id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      type: 'scan',
      content: 'https://example.com',
      createdAtMs: 1_700_000_000_000,
      verdict: 'safe',
      safeToOpen: true,
      reasons: ['HTTPS OK'],
    });

    const doc = mapHistoryItemToDocument('usr_test', 'event-1', 'req-abc', item);

    expect(doc.idUser).toBe('usr_test');
    expect(doc.eventId).toBe('event-1');
    expect(doc.content).toBe('https://example.com');
    expect(doc.consumedAt).toBeDefined();
  });
});
