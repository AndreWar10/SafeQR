import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';

export type ScanEventSaveResult = 'created' | 'exists';

export interface ScanEventRepository {
  save(envelope: QrAnalyzedEnvelope): Promise<ScanEventSaveResult>;
}
