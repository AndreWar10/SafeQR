import type {
  AnalyzeEventPublisherPort,
  QrAnalyzedPublishInput,
} from './analyze-event-publisher.port.js';

export class NullAnalyzeEventPublisher implements AnalyzeEventPublisherPort {
  async publishQrAnalyzed(_input: QrAnalyzedPublishInput): Promise<void> {
    // no-op (testes / PUBSUB_ENABLED=false)
  }
}
