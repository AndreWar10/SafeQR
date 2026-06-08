# Safe QR App

Aplicativo Flutter para **análise segura de QR codes** — *"Analise antes de abrir"*.

## O que faz

- **Ler** QR codes pela câmera e classificar risco (`safe`, `suspicious`, `unsafe`, `unknown`)
- **Gerar** QR codes (texto, URL, Wi-Fi, e-mail, telefone, SMS) e exportar PNG
- **Histórico** local de leituras e QR gerados (SQLite)
- Análise **local** (heurística on-device) ou **remota** (API `safe_qr_back`)

## Stack

Flutter · Dart 3.11 · Provider · get_it · Dio · sqflite · mobile_scanner · qr_flutter

## Início rápido

```bash
flutter pub get
cp assets/.env.example assets/.env   # ajustar API_BASE_URL
flutter run
```

| Modo | `.env` |
|------|--------|
| Sem backend | `ANALYZE_MODE=local` |
| Com backend | `ANALYZE_MODE=remote` + `API_BASE_URL=http://<IP>:3000` |

## Documentação

Documentação completa em **[`docs/`](./docs/README.md)**:

- [Visão geral](./docs/01-visao-geral.md)
- [Arquitetura](./docs/02-arquitetura.md)
- [Stack](./docs/03-stack-tecnologica.md)
- [Casos de uso](./docs/05-casos-de-uso.md)
- [API e integração](./docs/07-api-integracao.md)
- [Configuração](./docs/10-configuracao-ambiente.md)
- [Índice completo](./docs/README.md)

## Estrutura

```
lib/
├── app/          # Bootstrap, DI, MaterialApp
├── core/         # Config, rede, DB, tema, strings
├── features/     # splash, shell, qr_scanner, qr_generator, qr_history
└── shared/       # Widgets reutilizáveis
```

Cada feature tem README em `lib/features/<nome>/README.md`.

## Testes

```bash
flutter test
flutter analyze
```

## Monorepo

| Projeto | Caminho |
|---------|---------|
| App (este) | `safe_qr_app/` |
| API Node.js | `../safe_qr_back/` |
| Docs acadêmicos | `../docs/` |

## Versão

`1.0.0+1` — Sprint 1+
