import type { Message } from '@google-cloud/pubsub';

import type { Logger } from '../lib/logger.js';
import type { HistoryRepository } from '../repositories/history-repository.port.js';
import type { QrAnalyzedEnvelope } from '../schemas/qr-analyzed.schema.js';

export class QrAnalyzedHistoryHandler {
  constructor(private readonly logger: Logger, private readonly history: HistoryRepository) {}

  async handle(envelope: QrAnalyzedEnvelope, message: Message): Promise<void> {
    const { idUser, historyItem } = envelope.data;

    if (idUser == null) {
      this.logger.warn(
        { eventId: envelope.eventId, pubsubMessageId: message.id },
        'Evento sem idUser — histórico ignorado',
      );
      return;
    }

    if (historyItem == null) {
      this.logger.warn(
        { eventId: envelope.eventId, idUser, pubsubMessageId: message.id },
        'Evento sem historyItem — histórico ignorado (mensagem antiga ou publish sem idUser)',
      );
      return;
    }

    const firestoreResult = await this.history.save({
      idUser,
      eventId: envelope.eventId,
      correlationId: envelope.correlationId,
      item: historyItem,
    });

    this.logger.info(
      {
        event: 'qr_analyzed_history_consumed',
        eventId: envelope.eventId,
        correlationId: envelope.correlationId,
        idUser,
        historyItemId: historyItem.id,
        verdict: historyItem.verdict,
        firestore: {
          path: `history/${idUser}/items/${historyItem.id}`,
          result: firestoreResult,
        },
        pubsubMessageId: message.id,
      },
      'Evento qr.analyzed persistido no histórico',
    );
  }
}
