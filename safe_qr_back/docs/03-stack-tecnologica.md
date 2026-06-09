# 03 — Stack tecnológica

## Runtime e linguagem

| Item | Versão / detalhe |
|------|------------------|
| **Node.js** | ≥ 20 (LTS recomendado) |
| **TypeScript** | ^5.7.3 |
| **Módulos** | ESM (`"type": "module"`) |
| **Target** | ES2022 |
| **Module resolution** | NodeNext |

## Dependências de produção

| Pacote | Versão | Papel |
|--------|--------|-------|
| **fastify** | ^5.2.1 | Servidor HTTP de alta performance |
| **@fastify/cors** | ^10.0.2 | CORS (`origin: true`, GET/POST/OPTIONS) |
| **zod** | ^3.24.1 | Validação de env e body da API |
| **pino** | ^9.6.0 | Logs estruturados JSON |
| **dotenv** | ^16.6.1 | Carrega `.env` no bootstrap |
| **firebase-admin** | ^13.8.0 | Admin SDK — leitura Firestore (lista de clones) |

## Dependências de desenvolvimento

| Pacote | Versão | Papel |
|--------|--------|-------|
| **tsx** | ^4.19.2 | Execução TS em dev (`tsx watch`) |
| **typescript** | ^5.7.3 | Compilador |
| **vitest** | ^3.0.4 | Framework de testes |
| **eslint** | ^9.18.0 | Lint (flat config) |
| **typescript-eslint** | ^8.21.0 | Regras TS no ESLint |
| **prettier** | ^3.4.2 | Formatação |
| **pino-pretty** | ^13.0.0 | Logs legíveis em desenvolvimento |
| **@types/node** | ^22.10.5 | Tipos Node |

## Scripts npm

| Script | Comando | Descrição |
|--------|---------|-----------|
| `dev` | `tsx watch src/server.ts` | Servidor com hot-reload |
| `build` | `tsc -p tsconfig.build.json` | Compila para `dist/` |
| `start` | `node dist/server.js` | Produção (após build) |
| `test` | `vitest run` | Suite de testes (12 casos) |
| `test:watch` | `vitest` | Testes em modo watch |
| `lint` | `eslint .` | Análise estática |
| `lint:fix` | `eslint . --fix` | Corrige auto-fixáveis |
| `format` | `prettier --write "src/**/*.ts" "test/**/*.ts"` | Formata código |

## Configuração TypeScript

- **Strict mode:** ativado (`strict: true`)
- **Checks extras:** `noUnusedLocals`, `noUnusedParameters`, `noImplicitReturns`, `noFallthroughCasesInSwitch`
- **Build:** `tsconfig.build.json` emite para `dist/` com source maps e declarations
- **Dev/test:** `tsconfig.json` com `noEmit: true`

## Configuração de testes (Vitest)

```typescript
// vitest.config.ts
environment: 'node'
include: ['test/**/*.test.ts']
```

Testes usam `app.inject()` do Fastify (sem porta TCP real).

## Serviços externos

| Serviço | Uso | Obrigatório? |
|---------|-----|--------------|
| **Cloud Firestore** | Blocklist `suspicious_hosts/clones` + histórico `history/{uid}/items` | Não — opcional via credenciais |
| **Firebase Admin SDK** | `verifyIdToken` (analyze + history) + leitura/escrita Firestore | Obrigatório para auth em produção |
| **Cloud Pub/Sub** | Evento `qr.analyzed` após analyze 200 | Não — `PUBSUB_ENABLED=true` |

## Nuvem (ecossistema Google)

O projeto compartilha o **projeto Firebase** com o app Flutter:

- App Flutter: `firebase_core`, `cloud_firestore` (client SDK)
- Backend: `firebase-admin` (server SDK — `verifyIdToken`, blocklist, histórico Firestore)

Credenciais aceitas:

1. `GOOGLE_APPLICATION_CREDENTIALS` — caminho para JSON da conta de serviço
2. `FIREBASE_SERVICE_ACCOUNT_JSON` — JSON inline (CI/PaaS)
3. `applicationDefault()` — ADC do ambiente GCP (Cloud Run, GCE, etc.)

## Segurança da stack

| Prática | Implementação |
|---------|---------------|
| Segredos fora do Git | `.gitignore` para `.env`, `safe-qr-app-*.json` |
| Validação de entrada | Zod no body + limite de bytes no controller |
| Autenticação API | `Authorization: Bearer` + `verifyIdToken` em analyze e history |
| CORS | Aberto (`origin: true`) — adequado para dev; restringir em produção |
| TLS | Responsabilidade do proxy/reverse proxy em produção |
| Logs sem PII | Digest SHA-256 truncado (16 chars hex) |

## Comparação com o app mobile

| Aspecto | Backend (`safe_qr_back`) | Mobile (`safe_qr_app`) |
|---------|--------------------------|------------------------|
| Linguagem | TypeScript | Dart |
| HTTP server | Fastify | Dio (cliente) |
| Estado | Stateless | SQLite + Provider |
| Análise | Heurística + Firestore | Heurística local ou remota |
| Firebase | Admin SDK (read) | Client SDK (init) |
