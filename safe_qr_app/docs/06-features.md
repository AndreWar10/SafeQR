# 06 — Features (detalhamento)

## 1. Splash (`features/splash/`)

| Aspecto | Detalhe |
|---------|---------|
| **Página** | `SplashPage` |
| **Duração** | 1,4 s |
| **Transição** | `Navigator.pushReplacement` → `MainShellPage` |
| **Lógica** | Apenas timer; sem auth, sem preload de API |
| **Teste** | `test/features/splash/splash_smoke_test.dart` |

---

## 2. Shell (`features/shell/`)

| Aspecto | Detalhe |
|---------|---------|
| **Página** | `MainShellPage` |
| **Navegação** | `NavigationBar` + `IndexedStack` (preserva estado das abas) |
| **Abas** | 0=Ler, 1=Gerar, 2=Histórico |
| **Ações globais** | `ThemeCycleAction` no AppBar |
| **Comportamento** | Ao selecionar aba Histórico, chama `QrHistoryViewModel.load()` |

### Abas

| Índice | Label | Widget |
|--------|-------|--------|
| 0 | Ler | `QrReaderPage` |
| 1 | Gerar | `QrGeneratorPage` |
| 2 | Histórico | `QrHistoryPage` |

---

## 3. QR Scanner (`features/qr_scanner/`)

### Componentes principais

| Arquivo | Responsabilidade |
|---------|------------------|
| `QrReaderPage` | Câmera (`MobileScannerController`), debounce, overlay de análise |
| `QrReaderViewModel` | Orquestra análise remota/local e tratamento de erros |
| `ScanResultPage` | Exibe veredito, razões, ações (abrir/copiar) |
| `VerdictBadge` | Badge visual do veredito |
| `QrLocalHeuristicEngine` | Motor heurístico on-device |
| `RemoteQrAnalyzeRepository` | POST para API |
| `LocalHeuristicQrAnalyzeRepository` | Wrapper local com latência simulada |

### Fluxo na UI

```
QrReaderPage (câmera)
    → detecta barcode
    → overlay fullscreen (SafeQrLoadingOverlay)
    → QrReaderViewModel.analyzeDecoded()
    → ScanResultPage (push)
```

### Vereditos (`QrSecurityVerdict`)

| Valor | Significado UI |
|-------|----------------|
| `safe` | Verde — pode abrir com cautela |
| `suspicious` | Amarelo — atenção |
| `unsafe` | Vermelho — não recomendado |
| `unknown` | Cinza — origem incerta |

### Heurísticas locais (`QrLocalHeuristicEngine`)

| Sinal | Veredito típico |
|-------|-----------------|
| Conteúdo vazio | `unknown` |
| `WIFI:` | `unknown` + aviso de rede |
| `BEGIN:VCARD` | `unknown` + aviso de contato |
| `javascript:`, `data:`, `vbscript:`, `file:` | `unsafe` |
| `mailto:`, `tel:`, `sms:`, `geo:`, `intent:` | `suspicious` |
| `http://` (sem TLS) | `suspicious` |
| IP literal / localhost | `suspicious` |
| Encurtadores (bit.ly, t.co, etc.) | `suspicious` |
| `https://` sem sinais | `safe` |

**Encurtadores monitorados:** bit.ly, tinyurl.com, goo.gl, t.co, ow.ly, is.gd, cutt.ly, rebrand.ly, buff.ly

### Limites

- Conteúdo enviado à análise: **clip em 2000 caracteres** (`QrReaderViewModel`)
- Validação de geração: 1–2000 caracteres (`ValidateQrPayload`)

---

## 4. QR Generator (`features/qr_generator/`)

### Tipos (`QrGenerationType`)

```dart
enum QrGenerationType {
  plainText, url, imageUrl, wifi, email, phone, sms,
}
```

### ViewModel (`QrGeneratorViewModel`)

Gerencia:

- Tipo selecionado
- Campos de rascunho (texto, URL, Wi-Fi SSID/senha/segurança, e-mail assunto/corpo, SMS mensagem)
- Estado de geração (`generatedPayload`)
- Salvamento automático no histórico

### Páginas

| Página | Função |
|--------|--------|
| `QrGeneratorPage` | Formulário dinâmico por tipo |
| `QrGeneratorResultPage` | `QrImageView` + botões salvar/compartilhar |

### Export PNG (`QrPngBytes`)

Gera bytes PNG do QR para `gal` e `share_plus`. O QR **não embute arquivos binários** — tipo "imagem" gera URL de link.

---

## 5. QR History (`features/qr_history/`)

### Entidade (`HistoryItem`)

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | String (UUID) | PK |
| `type` | `scan` \| `generated` | |
| `content` | String | Payload completo |
| `createdAt` | DateTime | |
| `verdict` | String? | Apenas scans |
| `safeToOpen` | bool? | Apenas scans |
| `reasons` | List<String> | Apenas scans |

### Use cases

| Classe | Operação |
|--------|----------|
| `AddHistoryItem` | INSERT |
| `LoadHistoryList` | SELECT ORDER BY created_at_ms DESC |
| `DeleteHistoryItem` | DELETE BY id |
| `ClearHistory` | DELETE ALL |

### Repositório (modo remote)

- `RemoteHistoryRepository` — `GET/DELETE /v1/history` (Bearer via `AuthenticatedAppNetwork`)
- Scans **não** são gravados pelo app; o back persiste via Pub/Sub → Firestore
- QR gerado: `POST /v1/history` ao salvar no gerador

### UI (`QrHistoryPage`)

- Lista com `RefreshIndicator` (fonte: API em remote, SQLite em local)
- **Toque** → bottom sheet (conteúdo + razões)
- **Long press** → selecionar / desselecionar
- Com seleção → barra inferior com **Apagar selecionados**
- Sem seleção → `Dismissible` swipe-delete (um item)
- Estados: loading, erro, vazio

---

## 6. Core compartilhado

### Tema

- Material 3 com tokens em `AppColorTokens`
- Fontes: Plus Jakarta Sans (UI), JetBrains Mono (código/conteúdo raw)
- Modos: **claro** e **escuro** (alternância no AppBar); padrão primeira vez: **escuro**
- Persistido em `SharedPreferences` (`light` / `dark`)

### Logging (`AppDebugLog`)

| Tag | Uso |
|-----|-----|
| `SafeQR.Net` | Dio, health probe |
| `SafeQR.Reader` | Fluxo de scan/análise |
| `SafeQR.History` | GET/DELETE `/v1/history` |
| `SafeQR.Identity` | Firebase Anonymous + token |

Logs verbosos suprimidos em release (`kDebugMode`).

### Overlay compartilhado (`SafeQrLoadingOverlay`)

Usado em:

- Análise de QR (fullscreen route)
- Geração de QR (dialog 2s)
