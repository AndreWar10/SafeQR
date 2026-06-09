# 01 — Visão geral

## O que é o Safe QR

**Safe QR** é um aplicativo mobile multiplataforma (Flutter) que ajuda usuários a **analisar QR codes com segurança antes de abrir o destino**. A proposta central é: *"Analise antes de abrir"*.

Em vez de abrir imediatamente um link, rede Wi-Fi ou outro payload escaneado, o app:

1. Lê o conteúdo via câmera
2. Executa uma análise de segurança (local ou remota)
3. Apresenta um **veredito** com explicações em português
4. Permite que o usuário decida conscientemente: abrir, copiar ou voltar

## Problema que resolve

Usuários estão expostos a QR codes públicos (cardápios, pagamentos, Wi-Fi, campanhas) que podem encaminhar para:

- Phishing e sites clonados
- Deep links maliciosos
- Esquemas de pagamento fraudulentos
- Redes Wi-Fi suspeitas

O celular costuma abrir o destino **sem camada intermediária** de análise. O Safe QR insere essa camada.

## Proposta de valor

| Capacidade | Descrição |
|------------|-----------|
| **Leitor seguro** | Câmera sempre visível; análise automática ao detectar QR |
| **Feedback claro** | Veredito: `safe`, `suspicious`, `unsafe`, `unknown` + razões |
| **Ações conscientes** | Abrir URL externamente, copiar conteúdo, permanecer no app |
| **Gerador de QR** | Cria QR para texto, URL, Wi-Fi, e-mail, telefone, SMS |
| **Histórico** | Local (SQLite) ou nuvem (API), conforme `ANALYZE_MODE` |

## Escopo atual (Sprint 1+)

### Dentro do escopo

- Splash, shell com 3 abas, leitor com câmera real
- Análise heurística local (`QrLocalHeuristicEngine`)
- Integração com API remota (`POST /v1/qr/analyze`)
- Gerador funcional com export PNG (galeria + compartilhar)
- Histórico: SQLite (`local`) ou API Firestore (`remote`)
- Identidade Firebase Anonymous + Bearer JWT em pedidos remotos
- Tema claro/escuro (padrão escuro)
- Testes unitários e smoke tests

### Fora do escopo (explícito)

- Conta de usuário com e-mail/senha, login social
- Publicação em lojas (Play/App Store)
- Motor ML ou listas negras globais completas
- Conformidade LGPD ponta a ponta (apenas princípios documentados)

## Atores

| Ator | Papel |
|------|-------|
| **Usuário final** | Escaneia, gera QR, consulta histórico |
| **Motor de análise local** | Heurísticas on-device (`QrLocalHeuristicEngine`) |
| **Backend `safe_qr_back`** | API Node.js com análise remota + blocklist Firestore |
| **(Futuro) Administrador** | Gestão de listas, métricas |

## Posicionamento no monorepo

```
safe-qr-mobile/
├── safe_qr_app/     ← este projeto (Flutter)
├── safe_qr_back/    ← API Node.js parceira
└── docs/            ← documentação acadêmica (Sprint 1)
```

O app e o backend compartilham o **mesmo contrato HTTP** para análise de QR. O histórico fica **apenas no dispositivo**.

## Requisitos funcionais atendidos (RF-M)

| ID | Status |
|----|--------|
| RF-M01 Splash | ✅ |
| RF-M02 Leitor de QR | ✅ |
| RF-M03 Captura/decodificação | ✅ (`mobile_scanner`) |
| RF-M04 Envio para análise | ✅ (modo `remote`) ou heurística local |
| RF-M05 Resultado com classificação | ✅ |
| RF-M06 Ações pós-análise | ✅ (abrir, copiar, voltar) |
| RF-M07 Menu 3 abas | ✅ |
| RF-M08 Gerador | ✅ |
| RF-M09 Histórico local | ✅ |
| RF-M10 Erros de rede | ✅ |

Referência completa: [`../../docs/SPRINT-1-ENTREGAVEIS.md`](../../docs/SPRINT-1-ENTREGAVEIS.md)
