# 06 — Motor de análise (heurística S1)

O coração do backend é a classe `QrAnalyzeService` (`src/services/qr-analyze.service.ts`). Ela implementa a **heurística Sprint 1**, espelhando o motor local do app Flutter (`QrLocalHeuristicEngine`) para consistência entre modos `local` e `remote`.

## Pipeline de decisão

```
rawContent
    ↓ trim()
    ↓ vazio? → unknown
    ↓ WIFI:? → unknown (wifi)
    ↓ BEGIN:VCARD? → unknown (vcard)
    ↓ new URL(content)
    ↓
    ├─ URL válida com protocolo
    │   ├─ http/https → verificar blocklist → httpLike()
    │   ├─ javascript/data/vbscript/file/jscript → unsafe
    │   ├─ mailto/tel/sms/geo/market/intent/ftp → suspicious
    │   └─ outro esquema → unknown
    │
    ├─ contém "://" mas URL inválida → text (unknown)
    └─ texto puro → text (unknown)
```

## Vereditos

Definidos em `src/models/qr-verdict.ts`:

```typescript
const QrVerdict = {
  safe: 'safe',
  suspicious: 'suspicious',
  unsafe: 'unsafe',
  unknown: 'unknown',
} as const;
```

## Regras detalhadas

### 1. Conteúdo vazio

- **Condição:** string vazia após trim
- **Veredito:** `unknown`
- **Motivo:** "Conteúdo vazio."

### 2. Wi‑Fi (`WIFI:`)

- **Condição:** conteúdo começa com `WIFI:` (case insensitive)
- **Veredito:** `unknown`
- **Motivo:** orienta validar rede e local físico

### 3. vCard (`BEGIN:VCARD`)

- **Condição:** contém `BEGIN:VCARD`
- **Veredito:** `unknown`
- **Motivo:** contato — origem ainda importa

### 4. URLs HTTP/HTTPS

#### 4a. Blocklist Firestore (prioridade)

Antes da heurística HTTP, verifica `suspiciousHosts.isListedHostname(normalizedHost)`:

- **Match** → `unsafe`
- Motivos mencionam lista de alertas e Firestore `suspicious_hosts/clones`

#### 4b. Heurística `httpLike()`

| Sinal | Condição | Impacto |
|-------|----------|---------|
| Sem TLS | `scheme === 'http'` | Adiciona motivo; tende a `suspicious` |
| IP literal | IPv4 válido no host | Adiciona motivo |
| localhost | `localhost` ou `127.0.0.1` | Adiciona motivo |
| Encurtador | host em `URL_SHORTENER_HOSTS` | Adiciona motivo "destino opaco" |

**Encurtadores conhecidos:**

```
bit.ly, tinyurl.com, goo.gl, t.co, ow.ly,
is.gd, cutt.ly, rebrand.ly, buff.ly
```

**Matriz de resultado HTTP(S):**

| Cenário | Veredito | safeToOpen |
|---------|----------|------------|
| `https` sem sinais | `safe` | `true` |
| `https` com sinais (IP, encurtador) | `suspicious` | `false` |
| `http` (com ou sem sinais extras) | `suspicious` | `false` |
| Host ausente | `unknown` | `false` |

### 5. Esquemas perigosos

**Lista:** `javascript`, `data`, `vbscript`, `file`, `jscript`

- **Veredito:** `unsafe`
- **Motivo:** esquema perigoso com impacto elevado

### 6. Esquemas de aplicação externa

**Lista:** `mailto`, `tel`, `sms`, `smsto`, `geo`, `market`, `intent`, `ftp`

- **Veredito:** `suspicious`
- **Motivo:** abre aplicação externa — confirmar contexto

### 7. Outros esquemas

- **Veredito:** `unknown`
- **Motivo:** validação aprofundada em fase futura

### 8. Texto sem URL clara

- **Condição:** não parseia como URL http(s) válida
- **Veredito:** `unknown`
- **Motivos:** verificar origem física; pode incluir nota sobre `://` malformado

## Campo `parsed`

Resumo estruturado para o app exibir detalhes:

```typescript
type QrParsedSummary = {
  type?: string;    // url, text, wifi, vcard, empty, mailto, etc.
  scheme?: string;  // https, http, javascript, ...
  host?: string;    // hostname original (não normalizado)
};
```

## Geração de `requestId`

Cada resultado do service recebe um **novo UUID** via `randomUUID()` no método `result()`.

> **Nota:** O `requestId` da resposta HTTP do Fastify (`req.id`) é diferente do `requestId` no corpo JSON da análise. O app consome o do corpo JSON.

## Limitações conhecidas

| Limitação | Impacto |
|-----------|---------|
| Sem resolução de redirects | Encurtadores são flagados, destino final não verificado |
| Sem verificação de certificado TLS | HTTPS "seguro" é heurístico, não criptográfico |
| Sem typosquatting / homoglyphs | `amaz0n.com` só é detectado se estiver na blocklist |
| Sem rate limiting | API aberta em dev |
| Blocklist estática no Firestore | Requer gestão manual do documento `clones` |

## Alinhamento com o app Flutter

O app em modo `local` usa regras equivalentes. Ao evoluir o motor:

1. Alterar `QrAnalyzeService` no backend
2. Espelhar em `QrLocalHeuristicEngine` no Flutter
3. Atualizar testes em ambos os lados

## Exemplos de decisão

| Input | verdict | safeToOpen | parsed.type |
|-------|---------|------------|-------------|
| `https://example.com` | safe | true | url |
| `https://bit.ly/x` | suspicious | false | url |
| `http://192.168.0.1` | suspicious | false | url |
| `javascript:alert(1)` | unsafe | false | javascript |
| `mailto:a@b.com` | suspicious | false | mailto |
| `WIFI:T:Rede;P:senha;;` | unknown | false | wifi |
| `texto qualquer` | unknown | false | text |
