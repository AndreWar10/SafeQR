# 13 — Pub/Sub: evento `qr.analyzed` + histórico assíncrono

## Fluxo

```
App → POST /v1/qr/analyze (+ Bearer obrigatório)
        ↓
Back responde 200 imediato (veredito)
        ↓ fire-and-forget
Pub/Sub tópico safe-qr-analyze-events
        ↓ fan-out
consume:history → Firestore history/{idUser}/items/{eventId}
consume:audit   → Firestore scan_events/{eventId}   (opcional)
```

O histórico **não** é gravado síncrono no analyze — só pelo consumidor `safe_qr_messaging`.

Fan-out: ver [safe_qr_messaging/docs/02-FANOUT-HISTORICO-AUDIT.md](../../safe_qr_messaging/docs/02-FANOUT-HISTORICO-AUDIT.md).

---

## Regra de ouro — `idUser`

| Fonte | Obrigatório |
|-------|-------------|
| `Authorization: Bearer <JWT>` → `verifyIdToken` → `decoded.uid` | Sim |

Mesmo serviço (`FirebaseUserIdentityService`) em `/v1/history` e `/v1/qr/analyze`.  
`client.idUser` no body **não autentica** — só metadados opcionais.

---

## Quando publicar

| Momento | Ação |
|---------|------|
| Analyze HTTP 200 | Publica 1 mensagem |
| HTTP 4xx/5xx | Não publica |
| Pub/Sub falha | `warn` — não bloqueia resposta |

---

## Configuração (`.env`)

```env
GCP_PROJECT_ID=safe-qr-app
PUBSUB_ENABLED=true
PUBSUB_TOPIC=safe-qr-analyze-events
PUBSUB_GOOGLE_APPLICATION_CREDENTIALS=./credentials/pubsub-publisher.json
```

---

## Envelope JSON (schema v1)

```json
{
  "schemaVersion": "1",
  "eventId": "uuid-v4",
  "eventType": "qr.analyzed",
  "occurredAt": "2026-06-08T23:25:33.123Z",
  "source": "safe-qr-api",
  "correlationId": "request-id-fastify",
  "data": {
    "idUser": "Vb3ubOjy9RYt9AKpx3VzunBirEc2",
    "contentDigest": "a1b2c3d4e5f67890",
    "rawByteLength": 42,
    "verdict": "safe",
    "safeToOpen": true,
    "reasonCodes": ["HTTPS_OK"],
    "reasonsCount": 1,
    "parsed": { "type": "url", "scheme": "https", "host": "example.com" },
    "client": { "platform": "android", "appVersion": "1.0.0" },
    "analysisDurationMs": 85,
    "historyItem": {
      "id": "MESMO_UUID_QUE_eventId",
      "type": "scan",
      "content": "https://example.com",
      "createdAtMs": 1717881330123,
      "verdict": "safe",
      "safeToOpen": true,
      "reasons": ["HTTPS OK"]
    }
  }
}
```

### `historyItem` — sempre em analyze 200

Com Bearer obrigatório, todo `200` traz `idUser` e `historyItem` preenchido.

| Campo | Regra |
|-------|-------|
| `id` | = `eventId` |
| `type` | sempre `"scan"` |
| `content` | rawContent truncado em 2000 chars |
| `verdict` / `safeToOpen` / `reasons` | do resultado da análise |

> O warn `pubsub_qr_analyzed_no_iduser` não deve mais ocorrer em produção — indica chamada sem Bearer (agora `401` antes do publish).

### Attributes Pub/Sub

```json
{ "eventType": "qr.analyzed", "schemaVersion": "1", "verdict": "safe" }
```

---

## Consumidores (`safe_qr_messaging`)

```bash
cd safe_qr_messaging
npm run consume:history   # obrigatório — histórico do app
npm run consume:audit     # opcional — scan_events
```

| Script | Subscription | Destino |
|--------|--------------|---------|
| `consume:history` | `safe-qr-analyze-events-sub-history` | `history/{idUser}/items/{id}` |
| `consume:audit` | `safe-qr-analyze-events-sub` | `scan_events/{eventId}` |

Logs esperados:
- `pubsub_qr_analyzed_published` (back)
- `qr_analyzed_history_consumed` + `firestore.result: "created"` (consumer)

---

## Checklist de aceite

- [ ] Analyze 200 + Bearer → log `pubsub_qr_analyzed_published` com `eventId` e `idUser`
- [ ] Mensagem com `data.idUser` = UID do token
- [ ] `data.historyItem` sempre preenchido em analyze 200
- [ ] `consume:history` grava em Firestore
- [ ] `GET /v1/history` lista o scan com mesmo Bearer

---

## Código-fonte

| Arquivo | Papel |
|---------|-------|
| `src/controllers/qr-analyze.controller.ts` | Resolve idUser + fire-and-forget |
| `src/services/pubsub-analyze-event-publisher.ts` | Monta envelope + publish |
| `src/services/build-qr-analyzed-history-item.ts` | Monta `historyItem` |
| `src/services/derive-reason-codes.ts` | `reasonCodes` estáveis |
