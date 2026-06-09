# 12 — Segurança e privacidade

> Documento complementar: [`MOBILE-DADOS-EPRIVACIDADE.md`](./MOBILE-DADOS-EPRIVACIDADE.md) (RNF-02, Sprint 1)

## Princípios

| Princípio | Implementação |
|-----------|---------------|
| Minimização de dados | Modo `local` não envia QR ao servidor |
| Transparência | Veredito + razões exibidos ao usuário |
| Controle do usuário | Histórico apagável; abrir URL é decisão consciente |
| Sem conta | Nenhum login, token ou perfil |
| LGPD (evolução) | Políticas formais pendentes; princípios documentados |

---

## O que o app envia

### Modo `ANALYZE_MODE=remote`

| Dado | Enviado? | Destino |
|------|----------|---------|
| Conteúdo bruto do QR (`rawContent`) | Sim | `POST /v1/qr/analyze` |
| Versão do app | Sim | Campo `client.appVersion` |
| Plataforma | Sim | Campo `client.platform` |
| Identificador do usuário | Não | — |
| Localização | Não | — |
| Histórico | Não | Permanece no dispositivo |

Conteúdo é clipado em **2000 caracteres** antes do envio.

### Modo `ANALYZE_MODE=local`

**Nenhum dado do QR** é transmitido a servidor. Análise via `QrLocalHeuristicEngine` on-device.

---

## O que fica no aparelho

| Dado | Modo local | Modo remote |
|------|------------|-------------|
| Histórico de scans | SQLite | Firestore via API |
| Histórico de gerados | SQLite | Firestore via API (se salvo) |
| Preferência de tema | SharedPreferences `light`/`dark` | Igual |
| Sessão anónima | Firebase Auth SDK | Igual |

O usuário apaga itens por swipe, ou vários via seleção (long press) + **Apagar selecionados**.

Senhas Wi-Fi em QR gerados permanecem no payload `WIFI:...` do histórico.

---

## O que o app NÃO inclui (Sprint 1)

- Login com e-mail, Google, Apple, etc.
- Analytics de terceiros (Firebase Analytics não configurado)
- WebView embutido para URLs
- Armazenamento de credenciais do usuário

---

## Segurança técnica

### Comunicação

| Ambiente | Protocolo | Notas |
|----------|-----------|-------|
| Desenvolvimento | HTTP cleartext | `usesCleartextTraffic=true` no Android |
| Produção (RNF-01) | **HTTPS obrigatório** | Remover cleartext |

### Abertura de URLs

- `url_launcher` com `LaunchMode.externalApplication`
- Navegador do sistema — não executa JS dentro do app
- Botão "Abrir" respeita `safeToOpen` da análise

### Esquemas perigosos

Heurística local e remota flagam:

- `javascript:`, `data:`, `vbscript:`, `file:` → `unsafe`

### Backend (contexto)

O servidor loga **tamanho em bytes** e **hash SHA-256 truncado** — não o conteúdo raw completo nos logs estruturados. Ver documentação do backend.

### Firebase

- `firebase_core` + `firebase_auth` (sessão anónima → Bearer JWT)
- `cloud_firestore` não usado diretamente no app — histórico remoto via REST API do back

### Secrets

- `.env` empacotado em assets — **não commitar** URLs de produção ou chaves
- `firebase_options.dart` e `google-services.json` são configs públicas do projeto Firebase (não são secret keys de API)

### Release Android

Assinatura release ainda usa **debug keys** — inadequado para distribuição pública.

---

## Dados sensíveis no gerador Wi-Fi

QR Wi-Fi contém SSID e senha em texto no payload:

```
WIFI:T:WPA;S:minha-rede;P:senha123;;
```

Esses dados:

- Ficam no histórico (SQLite local ou nuvem, conforme modo)
- Podem ser compartilhados como PNG (usuário decide)
- **Não são enviados** ao backend a menos que o usuário escaneie o QR gerado em modo remote

Responsabilidade do usuário ao compartilhar QR de Wi-Fi.

---

## Evolução LGPD / remoto

Quando a API estiver em produção:

1. Documentar no backend: base legal, retenção, direitos do titular
2. App deve exibir política de privacidade e consentimento se exigido
3. Considerar modo "só análise local" como padrão com opt-in para remoto
4. Avaliar envio de hash em vez de conteúdo bruto

---

## Matriz de risco (resumo)

| Risco | Mitigação atual | Gap |
|-------|-----------------|-----|
| Phishing via QR | Análise heurística + feedback | Sem listas globais/ML |
| Exfiltração de conteúdo | Modo local disponível | Remote envia raw |
| Histórico vazado | Local only, apagável | Sem criptografia at-rest |
| MITM em dev | Cleartext HTTP | HTTPS em prod |
| Wi-Fi password leak | Aviso implícito | Sem warning explícito na UI |
