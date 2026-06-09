# Safe QR App — Documentação

Documentação técnica do aplicativo mobile **Safe QR** (`safe_qr_app`).

**Versão do app:** 1.0.0+1  
**Última atualização:** junho de 2026 — Bearer JWT via `AuthenticatedAppNetwork` em modo remote

---

## Índice

| # | Documento | Conteúdo |
|---|-----------|----------|
| 01 | [Visão geral](./01-visao-geral.md) | Problema, proposta de valor, escopo, atores |
| 02 | [Arquitetura](./02-arquitetura.md) | Camadas, padrões, diagramas, fluxo de dados |
| 03 | [Stack tecnológica](./03-stack-tecnologica.md) | Flutter, pacotes, versões, dependências |
| 04 | [Estrutura do projeto](./04-estrutura-projeto.md) | Árvore de pastas, convenções, módulos |
| 05 | [Casos de uso](./05-casos-de-uso.md) | Fluxos principais, extensões, diagramas UML |
| 06 | [Features](./06-features.md) | Splash, Shell, Scanner, Gerador, Histórico |
| 07 | [API e integração](./07-api-integracao.md) | Endpoints, contratos JSON, modos de análise |
| 08 | [Dados e persistência](./08-dados-persistencia.md) | Entidades, SQLite (local) / Firestore via API (remote) |
| 09 | [Navegação e UI](./09-navegacao-ui.md) | Rotas, telas, tema, componentes compartilhados |
| 10 | [Configuração e ambiente](./10-configuracao-ambiente.md) | `.env`, build, execução local |
| 11 | [Plataformas](./11-plataformas-android-ios.md) | Permissões, manifestos, Firebase |
| 12 | [Segurança e privacidade](./12-seguranca-privacidade.md) | LGPD, dados enviados, boas práticas |
| 13 | [Testes](./13-testes.md) | Cobertura, como rodar, convenções |
| 14 | [Desenvolvimento](./14-desenvolvimento.md) | Setup, debug, logs, convenções de código |
| 15 | [Roadmap e gaps](./15-roadmap-gaps.md) | Evolução planejada, débitos técnicos |
| 16 | [Requisitos app — backlog](./16-requisitos-app-backlog.md) | Conformidade RF-M/RNF e plano de execução (escopo mobile) |
| 17 | [Identidade Firebase Anonymous](./17-identidade-firebase-anonymous.md) | Bearer JWT, setup manual, arquitetura |

---

## Documentos relacionados (fora desta pasta)

| Documento | Localização |
|-----------|-------------|
| Privacidade mobile (RNF-02) | [`MOBILE-DADOS-EPRIVACIDADE.md`](./MOBILE-DADOS-EPRIVACIDADE.md) |
| Sprint 1 — entregáveis acadêmicos | [`../../docs/SPRINT-1-ENTREGAVEIS.md`](../../docs/SPRINT-1-ENTREGAVEIS.md) |
| Integração mobile (backend) | [`../../safe_qr_back/docs/10-integracao-mobile.md`](../../safe_qr_back/docs/10-integracao-mobile.md) |
| Pub/Sub + histórico assíncrono | [`../../safe_qr_messaging/docs/02-FANOUT-HISTORICO-AUDIT.md`](../../safe_qr_messaging/docs/02-FANOUT-HISTORICO-AUDIT.md) |
| Pub/Sub (produtor back) | [`../../safe_qr_back/docs/13-pubsub-qr-analyzed.md`](../../safe_qr_back/docs/13-pubsub-qr-analyzed.md) |
| API endpoints (backend) | [`../../safe_qr_back/docs/05-api-endpoints.md`](../../safe_qr_back/docs/05-api-endpoints.md) |
| READMEs por feature | `lib/features/*/README.md` |

---

## Resumo em uma frase

> App Flutter que **analisa QR codes antes de abrir**, com leitor de câmera, gerador de QR, histórico (SQLite local ou remoto via API + Pub/Sub) e análise heurística on-device ou via `safe_qr_back` com Bearer JWT.
