# 02 — Arquitetura

## Padrão arquitetural

O backend segue uma variante de **MVC com camadas desacopladas**, adequada a APIs REST pequenas e testáveis:

| Camada | Pasta | Responsabilidade |
|--------|-------|------------------|
| **Bootstrap** | `server.ts`, `app.ts` | Inicialização, CORS, error handler global |
| **Rotas** | `routes/` | Mapeamento HTTP → controller (sem lógica de negócio) |
| **Controllers** | `controllers/` | Validação de limites, logging da requisição, delegação ao service |
| **Services** | `services/` | Regras de análise, integração Firestore |
| **Models** | `models/` | Tipos de domínio (`QrAnalyzeResultModel`, vereditos) |
| **Schemas** | `schemas/` | Contratos de entrada (Zod) |
| **Views** | `views/` | Serialização JSON de sucesso e erro |
| **Config / Lib** | `config/`, `lib/` | Env tipado, fábrica de logger |

## Diagrama de componentes

```mermaid
flowchart TB
  subgraph entry[Bootstrap]
    SRV[server.ts]
    APP[app.ts]
    SRV --> APP
  end

  subgraph http[HTTP]
    R[v1.routes.ts]
    HC[HealthController]
    QC[QrAnalyzeController]
    R --> HC
    R --> QC
  end

  subgraph domain[Domínio]
    QS[QrAnalyzeService]
    SHP[SuspiciousHostsPort]
    FSH[FirestoreSuspiciousHostsPort]
    NSH[NullSuspiciousHostsPort]
    SHP -.-> FSH
    SHP -.-> NSH
    QS --> SHP
  end

  subgraph io[Entrada / Saída]
    ZS[qr-analyze.schema.ts]
    VR[qr-analyze-response.view.ts]
    ER[error-response.view.ts]
  end

  APP --> R
  QC --> ZS
  QC --> QS
  QC --> VR
  QC --> ER
  FSH --> FS[(Firestore)]
```

## Fluxo de inicialização

```
dotenv/config
    ↓
loadEnv() — valida process.env com Zod
    ↓
createLogger() — Pino (+ pino-pretty em dev)
    ↓
buildApp() — Fastify + CORS + rotas + error handler
    ↓
app.listen({ port, host: '0.0.0.0' })
```

### Decisão de porta Firestore (em `v1.routes.ts`)

```
GOOGLE_APPLICATION_CREDENTIALS definido?
    OU FIREBASE_SERVICE_ACCOUNT_JSON definido?
        SIM → FirestoreSuspiciousHostsPort (cache TTL configurável)
        NÃO → NullSuspiciousHostsPort (lista sempre vazia)
```

## Fluxo — `POST /v1/qr/analyze`

```mermaid
sequenceDiagram
  participant C as Cliente (Flutter)
  participant F as Fastify
  participant Ctrl as QrAnalyzeController
  participant Svc as QrAnalyzeService
  participant FS as Firestore (opcional)

  C->>F: POST /v1/qr/analyze { rawContent, client? }
  F->>Ctrl: postAnalyze(req, reply)
  Ctrl->>Ctrl: Zod safeParse(body)
  alt corpo inválido
    Ctrl-->>C: 400 VALIDATION_ERROR
  end
  Ctrl->>Ctrl: Buffer.byteLength > MAX_RAW_CONTENT_BYTES?
  alt payload grande
    Ctrl-->>C: 413 PAYLOAD_TOO_LARGE
  end
  Ctrl->>Ctrl: log info (byteLen, digest SHA-256[:16])
  Ctrl->>Svc: evaluateAsync(rawContent)
  Svc->>Svc: trim, classificar tipo (wifi/vcard/url/text)
  alt URL http(s)
    Svc->>FS: isListedHostname(host normalizado)
    FS-->>Svc: true/false
    alt na lista
      Svc-->>Ctrl: verdict=unsafe
    else heurística http(s)
      Svc-->>Ctrl: safe/suspicious/unknown
    end
  else outros esquemas
    Svc-->>Ctrl: unsafe/suspicious/unknown
  end
  Ctrl->>Ctrl: toQrAnalyzeResponseJson(model)
  Ctrl-->>C: 200 { requestId, verdict, safeToOpen, reasons, parsed }
```

## Injeção de dependências

Não há container DI (get_it, awilix). A composição é **manual** em `v1.routes.ts`:

```typescript
const analyzeService = new QrAnalyzeService(createSuspiciousHostsPort(env));
const qrAnalyze = new QrAnalyzeController({ env, service: analyzeService });
```

Isso mantém o projeto simples e permite substituir `SuspiciousHostsPort` nos testes.

## Error handling

| Camada | Comportamento |
|--------|---------------|
| Controller | Retorna `400` (Zod) e `413` (tamanho) via views |
| `app.setErrorHandler` | `400` para erros de validação Fastify; `500` genérico |
| Firestore | **Fail-open** — `console.warn` + retorna `false` (não lista) |

## Observabilidade

- **Request ID:** UUID gerado por requisição (`genReqId`), exposto no header `x-request-id`
- **Logs:** Pino com `base: { service: 'safe-qr-api' }`
- **Evento de análise:** `event: 'qr_analyze'` com `rawByteLength`, `contentDigest`, metadados do client

## Estrutura de pastas detalhada

```
src/
├── server.ts
├── app.ts
├── config/
│   └── env.ts
├── lib/
│   └── logger.ts
├── routes/
│   └── v1.routes.ts
├── controllers/
│   ├── health.controller.ts
│   └── qr-analyze.controller.ts
├── services/
│   ├── qr-analyze.service.ts
│   ├── suspicious-hosts-port.ts
│   ├── suspicious-hosts-firestore.ts
│   └── suspicious-hosts-match.ts
├── models/
│   ├── qr-verdict.ts
│   └── analyze-result.model.ts
├── schemas/
│   └── qr-analyze.schema.ts
└── views/
    ├── qr-analyze-response.view.ts
    └── error-response.view.ts
```

## Decisões arquiteturais (ADRs resumidos)

| Decisão | Alternativa considerada | Motivo da escolha |
|---------|-------------------------|-------------------|
| Fastify 5 | Express | Throughput, schema validation nativo, logger integrado |
| ESM (`type: module`) | CommonJS | Alinhado ao ecossistema Node moderno |
| Zod | JSON Schema / Joi | Tipagem inferida, DX no TypeScript |
| Porta `SuspiciousHostsPort` | Acoplamento direto ao Firestore | Testabilidade e modo offline |
| Fail-open Firestore | Fail-closed | UX: análise heurística ainda funciona sem nuvem |
| Sem BD servidor próprio | PostgreSQL | S1 focada em heurística; Firestore só para blocklist |
