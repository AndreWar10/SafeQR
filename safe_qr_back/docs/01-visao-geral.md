# 01 — Visão geral

## O que é o `safe-qr-back`

O **Safe QR Backend** (`safe-qr-back`) é a API REST do projeto acadêmico **Safe QR**. Ele recebe o **conteúdo bruto** decodificado de um QR Code (tipicamente uma URL, mas pode ser texto, vCard, Wi‑Fi, etc.) e devolve uma **classificação de segurança** com explicações em linguagem acessível.

O app Flutter (`safe_qr_app`) pode operar em dois modos:

| Modo | Comportamento |
|------|---------------|
| **local** | Heurística roda no dispositivo (`QrLocalHeuristicEngine`) |
| **remote** | App chama `POST /v1/qr/analyze` nesta API |

O motor remoto foi projetado para **espelhar** o motor local, garantindo vereditos consistentes entre os modos.

## Problema que resolve

QR Codes em ambientes públicos (cardápios, eventos, Wi‑Fi, campanhas) podem redirecionar para:

- Sites clonados (phishing)
- Esquemas perigosos (`javascript:`, `data:`)
- Encurtadores opacos (destino desconhecido)
- IPs literais disfarçados de sites legítimos

O backend atua como **camada de análise** entre a leitura do QR e a decisão do usuário de abrir o link.

## Escopo atual (v0.1.0)

### Dentro do escopo

- Health check para observabilidade e CI
- Análise heurística de payloads QR (Sprint 1)
- Validação de entrada com limites de tamanho
- Logs estruturados com privacidade (digest SHA-256, sem texto bruto)
- Integração opcional com **Firestore** para lista de domínios suspeitos (clones)
- **Autenticação Firebase** (`Bearer` JWT) em `POST /v1/qr/analyze` e CRUD `/v1/history`
- Histórico na nuvem (Firestore) + evento assíncrono `qr.analyzed` (Pub/Sub)
- Contrato REST versionado em `/v1`
- Testes automatizados (Vitest)

### Fora do escopo (por enquanto)

- CRUD completo de outros recursos no servidor
- Motor avançado (ML, sandbox, head requests, typosquatting)
- Deploy documentado em nuvem pública

## Atores e integrações

```mermaid
flowchart TB
  subgraph clientes
    APP[App Flutter - safe_qr_app]
    POSTMAN[Postman / curl / CI]
  end
  subgraph backend[safe-qr-back]
    API[Fastify :3000]
  end
  subgraph gcp[Google Cloud / Firebase]
    FS[(Firestore\nsuspicious_hosts/clones)]
  end
  APP -->|POST /v1/qr/analyze + Bearer| API
  APP -->|CRUD /v1/history + Bearer| API
  POSTMAN -->|GET /v1/health| API
  API -->|leitura opcional| FS
  API -->|history/{uid}/items| FS
```

## Requisitos atendidos

| ID | Descrição | Status |
|----|-----------|--------|
| RF-B01 | Health check (`GET /v1/health`) | ✅ |
| RF-B02 | `POST /v1/qr/analyze` com conteúdo bruto | ✅ |
| RF-B03 | Resposta com veredito, razões e metadados | ✅ |
| RF-B04 | Validação e erros padronizados (`4xx`) | ✅ |
| RF-B05 | Log estruturado sem PII desnecessária | ✅ |
| RF-B06 | Histórico server-side (`/v1/history` + Pub/Sub) | ✅ |
| RF-B07 | Auth Firebase em analyze e history | ✅ |

## Princípios de design

1. **Camadas desacopladas** — routes → controllers → services → models/views
2. **Porta injetável** — `SuspiciousHostsPort` permite mock em testes e `Null` sem credenciais
3. **Fail-open no Firestore** — se a lista remota falhar, a heurística local continua
4. **Privacidade por padrão** — logs usam digest truncado, não o conteúdo do QR
5. **Contrato estável** — JSON alinhado ao DTO do Flutter (`QrAnalyzeDto`)

## Métricas do projeto

| Métrica | Valor |
|---------|-------|
| Arquivos TypeScript em `src/` | 16 |
| Endpoints HTTP | 7 (2 health + 1 analyze + 4 history) |
| Testes automatizados | 38 (9 arquivos) |
| Dependências de produção | 6 |
| Node.js mínimo | 20 |
