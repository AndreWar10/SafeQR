# 05 — API — Endpoints (referência completa)

**Base URL (dev):** `http://localhost:3000` ou `http://<IP-LAN>:3000`  
**Versionamento:** prefixo `/v1`  
**Formato:** JSON (`Content-Type: application/json`)  
**Correlação:** header `x-request-id` (UUID gerado pelo servidor se ausente)

**Postman:** importar [`Safe-QR-API.postman_collection.json`](./Safe-QR-API.postman_collection.json)

---

## Variáveis Postman recomendadas

| Variável | Exemplo | Uso |
|----------|---------|-----|
| `baseUrl` | `http://localhost:3000` | URL base |
| `firebaseToken` | `eyJhbGciOiJSUzI1NiIs...` | JWT de `getIdToken()` — **analyze + history** |
| `historyItemId` | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | UUID do item |

> **Auth (analyze + history):** usar **Firebase ID Token** no `Authorization: Bearer`, **não** o UID.  
> `client.idUser` no body é metadado opcional — **não autentica**.

---

## Tabela resumo

| # | Método | Path | Auth | Descrição |
|---|--------|------|------|-----------|
| 1 | `GET` | `/v1/health` | Não | Health check |
| 2 | `GET` | `/health` | Não | Alias do health |
| 3 | `POST` | `/v1/qr/analyze` | **Bearer JWT** | Análise de QR |
| 4 | `POST` | `/v1/history` | **Bearer JWT** | Upsert item histórico |
| 5 | `GET` | `/v1/history` | **Bearer JWT** | Listar histórico |
| 6 | `DELETE` | `/v1/history/{id}` | **Bearer JWT** | Apagar um item |
| 7 | `DELETE` | `/v1/history` | **Bearer JWT** | Limpar histórico do user |

---

## 1. `GET /v1/health`

Verifica se a API está operacional.

**Headers:** nenhum  
**Body:** nenhum

**Response `200`:**
```json
{
  "status": "ok",
  "service": "safe-qr-api",
  "version": "0.1.0"
}
```

```bash
curl -s http://localhost:3000/v1/health
```

---

## 2. `GET /health`

Alias idêntico ao `/v1/health`.

```bash
curl -s http://localhost:3000/health
```

---

## 3. `POST /v1/qr/analyze`

Analisa o conteúdo bruto de um QR Code. **Requer Firebase ID Token** (igual ao histórico).

**Headers:**
```
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Body — HTTPS (safe):**
```json
{
  "rawContent": "https://example.com/path",
  "client": {
    "appVersion": "1.0.0",
    "platform": "android"
  }
}
```

> O app Flutter envia só `appVersion` e `platform` em `client`. O `idUser` vem **só** do JWT — não enviar UID no body.

**Body — encurtador (suspicious):**
```json
{
  "rawContent": "https://bit.ly/abc123",
  "client": { "platform": "android" }
}
```

**Body — javascript (unsafe):**
```json
{
  "rawContent": "javascript:alert(1)"
}
```

**Response `200`:**
```json
{
  "requestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "verdict": "safe",
  "safeToOpen": true,
  "reasons": [
    "Ligação `https` a um host textualmente reconhecível (heurística; não é recomendação absoluta)."
  ],
  "parsed": {
    "type": "url",
    "scheme": "https",
    "host": "example.com"
  }
}
```

| `verdict` | Significado |
|-----------|-------------|
| `safe` | HTTPS sem sinais de risco na heurística |
| `suspicious` | HTTP, encurtador, IP, esquemas externos |
| `unsafe` | Esquema perigoso ou host na blocklist Firestore |
| `unknown` | Tipo não classificável com confiança |

**Side-effect (200):** publica evento `qr.analyzed` no Pub/Sub se `PUBSUB_ENABLED=true`. O `idUser` vem **só** do Bearer. Ver [13-pubsub-qr-analyzed.md](./13-pubsub-qr-analyzed.md).

**Erros:** `401` sem Bearer · `400` validação · `413` payload > `MAX_RAW_CONTENT_BYTES` (8192 bytes UTF-8)

```bash
curl -s -X POST http://localhost:3000/v1/qr/analyze \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOi..." \
  -d '{"rawContent":"https://example.com","client":{"platform":"android"}}'
```

---

## 4. `POST /v1/history`

Cria ou atualiza item de histórico (upsert por `id`).

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <firebase-id-token>
```

**Body — scan:**
```json
{
  "item": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "type": "scan",
    "content": "https://example.com/path",
    "createdAtMs": 1717689600123,
    "verdict": "suspicious",
    "safeToOpen": false,
    "reasons": [
      "URL usa redirecionador conhecido (destino não visível diretamente)."
    ]
  },
  "client": {
    "appVersion": "1.0.0",
    "platform": "android"
  }
}
```

**Body — generated:**
```json
{
  "item": {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "type": "generated",
    "content": "WIFI:T:WPA;S:MinhaRede;P:senha123;;",
    "createdAtMs": 1717689700456,
    "verdict": null,
    "safeToOpen": null,
    "reasons": ["Tipo: wifi"]
  },
  "client": {
    "appVersion": "1.0.0",
    "platform": "android"
  }
}
```

**Response `201`:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "idUser": "Vb3ubOjy9RYt9AKpx3VzunBirEc2",
  "savedAt": "2026-06-08T12:00:00.123Z"
}
```

> `idUser` na resposta vem do **token** (`decoded.uid`), não do body.

**Firestore:** `history/{idUser}/items/{id}`

**Erros:** `400` · `401` token inválido · `413` content > 2000 chars · `503` sem credenciais Firebase no servidor

---

## 5. `GET /v1/history`

Lista histórico do utilizador autenticado, mais recente primeiro.

**Headers:**
```
Authorization: Bearer <firebase-id-token>
```

**Query params:**

| Param | Default | Max |
|-------|---------|-----|
| `limit` | 100 | 500 |
| `offset` | 0 | — |

**Response `200`:**
```json
{
  "items": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "type": "scan",
      "content": "https://example.com/path",
      "createdAtMs": 1717689600123,
      "verdict": "suspicious",
      "safeToOpen": false,
      "reasons": ["URL usa redirecionador conhecido..."]
    }
  ],
  "total": 1
}
```

```bash
curl -s "http://localhost:3000/v1/history?limit=100&offset=0" \
  -H "Authorization: Bearer eyJhbGciOi..."
```

---

## 6. `DELETE /v1/history/{id}`

Apaga um item. Só apaga se pertencer ao `idUser` do token.

**Headers:**
```
Authorization: Bearer <firebase-id-token>
```

**Response:** `204 No Content`  
**Erros:** `401` · `404` item inexistente ou de outro user

```bash
curl -s -X DELETE "http://localhost:3000/v1/history/a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  -H "Authorization: Bearer eyJhbGciOi..."
```

---

## 7. `DELETE /v1/history`

Apaga **todo** o histórico do utilizador autenticado.

**Headers:**
```
Authorization: Bearer <firebase-id-token>
```

**Response:** `204 No Content`

```bash
curl -s -X DELETE http://localhost:3000/v1/history \
  -H "Authorization: Bearer eyJhbGciOi..."
```

---

## Autenticação (`/v1/qr/analyze` + `/v1/history`)

Mesmo contrato nos dois fluxos — `FirebaseUserIdentityService` + `verifyIdToken`.

```
App: getIdToken() → JWT (eyJ...)
        ↓
Header: Authorization: Bearer <JWT>
        ↓
Back: firebase-admin verifyIdToken()
        ↓
decoded.uid → idUser (ex.: Vb3ubOjy9RYt9AKpx3VzunBirEc2)
        ↓
Analyze 200 → Pub/Sub qr.analyzed (historyItem assíncrono)
History     → Firestore history/{idUser}/items/{itemId}
```

| Enviar | Válido? |
|--------|---------|
| Firebase ID Token (`eyJ…`) | ✅ |
| UID no Bearer | ❌ |
| `client.idUser` no body | ❌ (não autentica) |
| Request sem `Authorization` | ❌ → `401` |

Detalhes histórico: [12-api-historico.md](./12-api-historico.md) · Pub/Sub: [13-pubsub-qr-analyzed.md](./13-pubsub-qr-analyzed.md)

---

## Erros padronizados

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Corpo inválido.",
  "requestId": "uuid",
  "details": { "fieldErrors": { ... } }
}
```

| Status | Código | Quando |
|--------|--------|--------|
| `400` | `VALIDATION_ERROR` | Body/query inválido |
| `401` | `UNAUTHORIZED` | Bearer ausente ou JWT inválido/expirado |
| `404` | `NOT_FOUND` | Item de histórico não encontrado |
| `413` | `PAYLOAD_TOO_LARGE` | Conteúdo acima do limite |
| `500` | `INTERNAL_ERROR` | Erro interno |
| `503` | `UNAUTHORIZED` | Servidor sem credenciais Firebase |

---

## CORS

| Opção | Valor |
|-------|-------|
| `origin` | `true` |
| `methods` | `GET`, `POST`, `DELETE`, `OPTIONS` |
| `allowedHeaders` | `Content-Type`, `x-request-id`, `Authorization` |
