import type { Message } from '@google-cloud/pubsub';

import type { Logger } from '../lib/logger.js';
import type { ScanEventRepository } from '../repositories/scan-event-repository.port.js';
import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';

export class QrAnalyzedAuditHandler {
  constructor(
    private readonly logger: Logger,
    private readonly scanEvents: ScanEventRepository,
    private readonly firestoreCollection: string,
  ) {}

  async handle(envelope: QrAnalyzedEnvelope, message: Message): Promise<void> {
    const firestoreResult = await this.scanEvents.save(envelope);

    this.logger.info(
      {
        event: 'qr_analyzed_audit_consumed',
        eventId: envelope.eventId,
        correlationId: envelope.correlationId,
        idUser: envelope.data.idUser,
        verdict: envelope.data.verdict,
        contentDigest: envelope.data.contentDigest,
        host: envelope.data.parsed?.host,
        firestore: {
          collection: this.firestoreCollection,
          result: firestoreResult,
        },
        pubsubMessageId: message.id,
      },
      'Evento qr.analyzed persistido em scan_events',
    );
  }
}
