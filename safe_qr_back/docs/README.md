# Safe QR — Documentação do Backend (`safe-qr-back`)

Documentação técnica completa da API REST do projeto **Safe QR**. Este backend analisa o conteúdo de QR Codes e devolve um veredito de segurança para o app Flutter.

## Índice

| # | Documento | Conteúdo |
|---|-----------|----------|
| 01 | [Visão geral](./01-visao-geral.md) | O que é, para quem serve, escopo atual |
| 02 | [Arquitetura](./02-arquitetura.md) | Camadas, fluxos, diagramas, padrões |
| 03 | [Stack tecnológica](./03-stack-tecnologica.md) | Runtime, libs, ferramentas, versões |
| 04 | [Casos de uso](./04-casos-de-uso.md) | Atores, fluxos, requisitos funcionais |
| 05 | [API — Endpoints](./05-api-endpoints.md) | Contratos HTTP, exemplos, erros |
| 06 | [Motor de análise](./06-motor-analise.md) | Heurísticas S1, vereditos, regras |
| 07 | [Integração Firestore](./07-integracao-firestore.md) | Lista de clones, cache, credenciais |
| 08 | [Configuração e deploy](./08-configuracao-deploy.md) | `.env`, scripts, produção |
| 09 | [Testes e qualidade](./09-testes-qualidade.md) | Vitest, ESLint, cobertura |
| 10 | [Integração mobile](./10-integracao-mobile.md) | Contrato com o app Flutter |
| 11 | [Roadmap e evolução](./11-roadmap-evolucao.md) | Próximas sprints, gaps, Pub/Sub |
| 12 | [API de Histórico](./12-api-historico.md) | CRUD `/v1/history`, auth, Firestore |
| 13 | [Pub/Sub qr.analyzed](./13-pubsub-qr-analyzed.md) | Evento + histórico assíncrono |

## Resumo em 30 segundos

- **O quê:** API Node.js (TypeScript) que recebe o texto bruto de um QR Code e responde com `verdict`, `safeToOpen`, `reasons` e `parsed`.
- **Como:** Fastify + Zod + heurística local (espelhando o motor do app) + lista opcional de domínios suspeitos no **Firestore**.
- **Endpoints atuais:** `GET /v1/health`, `POST /v1/qr/analyze` (**Bearer obrigatório**), CRUD `/v1/history` (**Bearer obrigatório**).
- **Auth:** Firebase ID Token (`getIdToken()`) em analyze e history — `client.idUser` no body não autentica.
- **Mensageria:** Pub/Sub `qr.analyzed` → `safe_qr_messaging` (histórico + auditoria). Ver doc 13.
- **Versão:** `0.1.0` (Sprint 1 + Firestore + histórico + Pub/Sub).

## Estrutura do código-fonte

```
safe_qr_back/
├── src/
│   ├── server.ts              # Entry point — sobe o HTTP server
│   ├── app.ts                 # Fábrica Fastify (CORS, rotas, error handler)
│   ├── config/env.ts          # Variáveis de ambiente tipadas (Zod)
│   ├── lib/logger.ts          # Pino (logs estruturados)
│   ├── routes/v1.routes.ts    # Registro de rotas /v1
│   ├── controllers/           # Orquestração HTTP (analyze, history, health)
│   ├── services/              # Regras de negócio + Firestore + auth
│   ├── models/                # Tipos de domínio
│   ├── schemas/               # Validação de entrada (Zod)
│   └── views/                 # Serialização JSON de resposta/erro
├── test/                      # Vitest (38 testes)
├── docs/Safe-QR-API.postman_collection.json
├── docs/                      # Esta documentação
├── .env.example
└── package.json
```

## Comandos rápidos

```bash
cd safe_qr_back
cp .env.example .env
npm install
npm run dev      # desenvolvimento com hot-reload
npm test         # 38 testes
npm run build && npm start   # produção
```

## Documentação relacionada no monorepo

- [`../../docs/SPRINT-1-ENTREGAVEIS.md`](../../docs/SPRINT-1-ENTREGAVEIS.md) — requisitos acadêmicos Sprint 1
- [`../../docs/SPRINT-2-STATUS-E-PROXIMA-ENTREGA.md`](../../docs/SPRINT-2-STATUS-E-PROXIMA-ENTREGA.md) — status Sprint 2 e roadmap
- [`../README.md`](../README.md) — README operacional do backend

---

*Última atualização: junho de 2026 — auth Firebase obrigatória; app Flutter usa `AuthenticatedAppNetwork` (Bearer automático).*
