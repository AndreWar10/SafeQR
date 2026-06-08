# 05 — API — Endpoints

**Base URL (desenvolvimento):** `http://localhost:3000`  
**Versionamento:** prefixo `/v1`  
**Formato:** JSON (`Content-Type: application/json`)  
**Correlação:** header `x-request-id` (UUID gerado pelo servidor se ausente)

---

## `GET /v1/health`

Verifica se a API está operacional.

### Request

```http
GET /v1/health HTTP/1.1
Host: localhost:3000
```

### Response `200 OK`

```json
{
  "status": "ok",
  "service": "safe-qr-api",
  "version": "0.1.0"
}
```

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `status` | string | Sempre `"ok"` quando saudável |
| `service` | string | Identificador fixo `"safe-qr-api"` |
| `version` | string | Versão do pacote npm (`0.1.0`) |

---

## `GET /health`

**Alias** idêntico a `GET /v1/health`. Mesma resposta.

---

## `POST /v1/qr/analyze`

Analisa o conteúdo bruto de um QR Code e devolve veredito de segurança.

### Request

```http
POST /v1/qr/analyze HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "rawContent": "https://example.com/path",
  "client": {
    "appVersion": "1.0.0",
    "platform": "android"
  }
}
```

### Body schema

| Campo | Tipo | Obrigatório | Validação |
|-------|------|-------------|-----------|
| `rawContent` | string | Sim | `min(1)`, `max(200_000)` no Zod |
| `client` | object | Não | Metadados do app |
| `client.appVersion` | string | Não | `max(64)` |
| `client.platform` | string | Não | `max(32)` — ex.: `android`, `ios` |

**Nota:** Além da validação Zod, o controller aplica limite de **bytes UTF-8** via `MAX_RAW_CONTENT_BYTES` (padrão 8192). Um string longo em caracteres multibyte pode atingir o limite de bytes antes do max Zod.

### Response `200 OK`

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

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `requestId` | string (UUID) | ID da análise (gerado no service) |
| `verdict` | enum | `safe` \| `suspicious` \| `unsafe` \| `unknown` |
| `safeToOpen` | boolean | Indicação prática para o app |
| `reasons` | string[] | Explicações em português |
| `parsed.type` | string | Tipo detectado: `url`, `text`, `wifi`, `vcard`, `empty`, esquema |
| `parsed.scheme` | string? | Ex.: `https`, `http`, `mailto` |
| `parsed.host` | string? | Hostname original (preserva casing do URL) |

### Valores de `verdict`

| Valor | Significado | `safeToOpen` típico |
|-------|-------------|---------------------|
| `safe` | HTTPS sem sinais de risco na heurística | `true` |
| `suspicious` | Sinais de atenção (HTTP, encurtador, IP, esquemas externos) | `false` |
| `unsafe` | Esquema perigoso ou host na blocklist Firestore | `false` |
| `unknown` | Tipo não classificável com confiança | `false` |

---

### Erros

#### `400 Bad Request` — Validação

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Corpo inválido.",
  "requestId": "uuid-da-requisicao",
  "details": {
    "fieldErrors": {
      "rawContent": ["rawContent é obrigatório"]
    }
  }
}
```

**Causas comuns:**

- `rawContent` ausente, vazio ou tipo incorreto
- `client` com campos inválidos

#### `413 Payload Too Large`

```json
{
  "error": "PAYLOAD_TOO_LARGE",
  "message": "Conteúdo excede o limite de 8192 bytes (UTF-8).",
  "requestId": "uuid-da-requisicao"
}
```

#### `500 Internal Server Error`

```json
{
  "error": "INTERNAL_ERROR",
  "message": "Erro interno.",
  "requestId": "uuid-da-requisicao"
}
```

---

## CORS

Configurado em `app.ts`:

| Opção | Valor |
|-------|-------|
| `origin` | `true` (reflete origin do request) |
| `methods` | `GET`, `POST`, `OPTIONS` |
| `allowedHeaders` | `Content-Type`, `x-request-id` |

---

## Exemplos com curl

### Health

```bash
curl -s http://localhost:3000/v1/health | jq
```

### Análise — URL segura

```bash
curl -s -X POST http://localhost:3000/v1/qr/analyze \
  -H "Content-Type: application/json" \
  -d '{"rawContent":"https://example.com","client":{"platform":"android","appVersion":"1.0.0"}}' | jq
```

### Análise — encurtador

```bash
curl -s -X POST http://localhost:3000/v1/qr/analyze \
  -H "Content-Type: application/json" \
  -d '{"rawContent":"https://bit.ly/abc123"}' | jq
```

### Análise — esquema perigoso

```bash
curl -s -X POST http://localhost:3000/v1/qr/analyze \
  -H "Content-Type: application/json" \
  -d '{"rawContent":"javascript:alert(1)"}' | jq
```

### Erro de validação

```bash
curl -s -X POST http://localhost:3000/v1/qr/analyze \
  -H "Content-Type: application/json" \
  -d '{"rawContent":""}' | jq
```

---

## Tabela resumo de endpoints

| Método | Path | Auth | Descrição |
|--------|------|------|-----------|
| `GET` | `/v1/health` | Não | Health check versionado |
| `GET` | `/health` | Não | Alias do health |
| `POST` | `/v1/qr/analyze` | Não | Análise de QR |

**Endpoints futuros planejados:** ver [11-roadmap-evolucao.md](./11-roadmap-evolucao.md).
