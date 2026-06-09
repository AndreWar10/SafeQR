/** Cache em memória para dedupe de `eventId` (at-least-once). */
export class ProcessedEventCache {
  private readonly ids = new Set<string>();
  private readonly maxSize: number;

  constructor(maxSize = 10_000) {
    this.maxSize = maxSize;
  }

  has(eventId: string): boolean {
    return this.ids.has(eventId);
  }

  add(eventId: string): void {
    if (this.ids.size >= this.maxSize) {
      const first = this.ids.values().next().value;
      if (first !== undefined) {
        this.ids.delete(first);
      }
    }
    this.ids.add(eventId);
  }
}
