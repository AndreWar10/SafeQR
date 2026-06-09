import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';
import type { ScanEventRepository, ScanEventSaveResult } from './scan-event-repository.port.js';

export class NullScanEventRepository implements ScanEventRepository {
  async save(_envelope: QrAnalyzedEnvelope): Promise<ScanEventSaveResult> {
    return 'created';
  }
}
