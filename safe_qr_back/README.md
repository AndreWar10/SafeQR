# Safe QR — API (`safe-qr-back`)

Backend **Node.js (TypeScript)** do projeto Safe QR, alinhado ao **Sprint 1** em [`../safe-qr-mobile/docs/SPRINT-1-ENTREGAVEIS.md`](../safe-qr-mobile/docs/SPRINT-1-ENTREGAVEIS.md): **Fastify**, validação com **Zod**, logs estruturados (**Pino**), contrato REST versionado em **`/v1`**.

## Arquitetura (MVC + desacoplamento)

| Camada | Pasta | Papel |
|--------|--------|--------|
| **Rotas** | `src/routes/` | Registro HTTP → controllers (sem regra de negócio). |
| **Controllers** | `src/controllers/` | Orquestra validação, limites, logging da requisição; delega ao **Service**. |
| **Services** | `src/services/` | Regras de análise (heurística S1, espelhando o motor local do app Flutter). |
| **Models** | `src/models/` | Tipos de domínio (`QrAnalyzeResultModel`, vereditos). |
| **Views** | `src/views/` | Serialização do corpo de resposta / erros padronizados (`4xx`/`5xx` + JSON). |
| **Schemas** | `src/schemas/` | Contratos de entrada (Zod). |
| **Config / Lib** | `src/config/`, `src/lib/` | Variáveis de ambiente tipadas e fábrica de logger. |

Persistência e filas ficam **fora do escopo S1** (interfaces futuras podem surgir em `repositories/` sem acoplar o controller).

## Requisitos

- **Node.js 20+** (LTS recomendado).

## Configuração

```bash
cd safe-qr-back
cp .env.example .env
npm install
```

Variáveis principais (ver `.env.example`):

- `PORT` — porta HTTP (padrão `3000`).
- `MAX_RAW_CONTENT_BYTES` — limite do corpo UTF-8 para `rawContent` (retorno `413` se exceder).
- `LOG_LEVEL` — nível Pino (`info`, `debug`, …).

## Scripts

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Servidor com reload (`tsx watch`). |
| `npm run build` | Compila para `dist/` (ESM). |
| `npm start` | Executa `dist/server.js` (após `build`). |
| `npm test` | Vitest (health + contrato `analyze`). |
| `npm run lint` | ESLint. |

## Endpoints (S1)

### `GET /v1/health` e `GET /health`

Health check (**RF-B01**): `200` + JSON `{ status, service, version }`.

### `POST /v1/qr/analyze`

**RF-B02–B04**: corpo JSON validado:

```json
{
  "rawContent": "https://exemplo.com",
  "client": { "appVersion": "1.0.0", "platform": "android" }
}
```

Resposta `200` no formato esperado pelo app (`requestId`, `verdict`, `safeToOpen`, `reasons`, `parsed`).

- `400` — validação (corpo inválido).
- `413` — conteúdo acima de `MAX_RAW_CONTENT_BYTES`.

## Privacidade e logs (S1)

Logs estruturados incluem **tamanho em bytes** e um **digest curto (SHA-256 truncado)** do conteúdo para correlação **sem** armazenar o texto bruto do QR (**RF-B05** / RNF privacidade).

## Integração com o app Flutter

Aponte a base URL do cliente HTTP para `http://<host>:<PORT>` (ou HTTPS atrás de proxy) e mantenha o path **`/v1/qr/analyze`** conforme `AppEndpoints` no mobile.

## Licença

Definir conforme política do grupo / curso (repositório acadêmico).
