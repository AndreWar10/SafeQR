import { FieldValue, Timestamp } from 'firebase-admin/firestore';

import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';

export type ScanEventDocument = {
  eventId: string;
  eventType: 'qr.analyzed';
  schemaVersion: '1';
  source: 'safe-qr-api';
  correlationId: string;
  occurredAt: Timestamp;
  idUser: string | null;
  contentDigest: string;
  rawByteLength: number;
  verdict: QrAnalyzedEnvelope['data']['verdict'];
  safeToOpen: boolean;
  reasonCodes: string[];
  reasonsCount: number;
  parsed: QrAnalyzedEnvelope['data']['parsed'];
  client: QrAnalyzedEnvelope['data']['client'];
  analysisDurationMs: number;
  consumedAt: FieldValue;
};

export function mapEnvelopeToScanEventDocument(envelope: QrAnalyzedEnvelope): ScanEventDocument {
  const { data } = envelope;

  return {
    eventId: envelope.eventId,
    eventType: envelope.eventType,
    schemaVersion: envelope.schemaVersion,
    source: envelope.source,
    correlationId: envelope.correlationId,
    occurredAt: Timestamp.fromDate(new Date(envelope.occurredAt)),
    idUser: data.idUser,
    contentDigest: data.contentDigest,
    rawByteLength: data.rawByteLength,
    verdict: data.verdict,
    safeToOpen: data.safeToOpen,
    reasonCodes: data.reasonCodes,
    reasonsCount: data.reasonsCount,
    parsed: data.parsed,
    client: data.client,
    analysisDurationMs: data.analysisDurationMs,
    consumedAt: FieldValue.serverTimestamp(),
  };
}
