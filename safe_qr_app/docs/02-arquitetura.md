# 02 — Arquitetura

## Padrão arquitetural

O app segue **Clean Architecture orientada a features**, com três camadas por módulo:

```
presentation/  →  Páginas, ViewModels (ChangeNotifier), widgets
domain/        →  Entidades, contratos de repositório, casos de uso
data/          →  DTOs, mappers, implementações de repositório, engines locais
```

### Princípios

- **Separação de responsabilidades:** UI não conhece Dio nem SQLite diretamente
- **Inversão de dependência:** domínio define contratos; data implementa
- **Feature-first:** cada funcionalidade é autocontida em `lib/features/`
- **DI centralizada:** `get_it` registra dependências em `app/di/dependency_injection.dart`

## Visão em camadas

```mermaid
flowchart TB
  subgraph presentation [Presentation]
    Pages[Páginas / Widgets]
    VM[ViewModels - ChangeNotifier]
  end
  subgraph domain [Domain]
    UC[Use Cases]
    RepoAbs[Repository Contracts]
    Entities[Entities]
  end
  subgraph data [Data]
    RepoImpl[Repository Implementations]
    DTO[DTOs / Mappers]
    Engine[QrLocalHeuristicEngine]
    SQLite[(sqflite)]
  end
  subgraph infra [Core / Infra]
    Dio[DioAppNetwork]
    Config[AppConfig]
    Theme[AppTheme]
  end

  Pages --> VM
  VM --> UC
  UC --> RepoAbs
  RepoImpl -.-> RepoImpl
  RepoImpl --> SQLite
  RepoImpl --> Dio
  RepoImpl --> Engine
  UC --> RepoAbs
```

## Bootstrap da aplicação

```mermaid
sequenceDiagram
  participant M as main.dart
  participant FB as Firebase
  participant ENV as dotenv
  participant DI as configureDependencies
  participant APP as SafeQrRoot

  M->>FB: initializeApp()
  M->>ENV: load assets/.env
  M->>ENV: AppConfig.fromEnv()
  M->>DI: configureDependencies()
  Note over DI: sqflite, Dio, repositories, ViewModels
  M->>APP: runApp()
```

**Arquivo de entrada:** `lib/main.dart`

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp()`
3. `dotenv.load(fileName: 'assets/.env')`
4. `AppConfig.fromEnv()`
5. `configureDependencies()` — registra tudo no `GetIt`
6. `runApp(SafeQrRoot())`

## Fluxo de análise de QR (principal)

```mermaid
sequenceDiagram
  participant U as Usuário
  participant R as QrReaderPage
  participant VM as QrReaderViewModel
  participant UC as AnalyzeQrCode
  participant Repo as QrAnalyzeRepository
  participant Hist as AddHistoryItem
  participant DB as SQLite

  U->>R: Aponta câmera ao QR
  R->>VM: analyzeDecoded(content)
  VM->>UC: call(rawContent)
  alt ANALYZE_MODE=local
    UC->>Repo: LocalHeuristicQrAnalyzeRepository
    Repo->>Repo: QrLocalHeuristicEngine.evaluate()
  else ANALYZE_MODE=remote
    UC->>Repo: RemoteQrAnalyzeRepository
    Repo->>Repo: POST /v1/qr/analyze
  end
  Repo-->>UC: QrAnalysisResult
  UC-->>VM: resultado
  VM->>Hist: add(HistoryItem)
  Hist->>DB: INSERT
  VM-->>R: QrAnalysisResult
  R->>R: push ScanResultPage
```

## Injeção de dependências

Registrado em `lib/app/di/dependency_injection.dart`:

| Tipo | Escopo | Implementação |
|------|--------|---------------|
| `AppConfig` | Singleton | Carregado do `.env` |
| `SharedPreferences` | Singleton | Preferências do SO |
| `AppThemeModeController` | Singleton | Tema persistido |
| `Database` | Singleton | `AppDatabaseBootstrapper` |
| `HistoryRepository` | Lazy singleton | `HistoryRepositoryImpl` |
| `QrAnalyzeRepository` | Lazy singleton | Local **ou** Remote (conforme `ANALYZE_MODE`) |
| `Dio` / `AppNetwork` | Singleton / Lazy | `DioAppNetwork` |
| ViewModels | Lazy singleton | `QrReaderViewModel`, `QrGeneratorViewModel`, `QrHistoryViewModel` |
| Use cases | Lazy singleton | `AnalyzeQrCode`, `AddHistoryItem`, etc. |

### Seleção do motor de análise

```dart
if (cfg.analyzeMode == AnalyzeMode.local) {
  return const LocalHeuristicQrAnalyzeRepository(QrLocalHeuristicEngine());
}
return RemoteQrAnalyzeRepository(sl());
```

## Estado na UI

- **Provider** (`MultiProvider` em `SafeQrRoot`) expõe ViewModels e `AppThemeModeController`
- ViewModels estendem `ChangeNotifier` e chamam `notifyListeners()` após mudanças
- Páginas consomem via `context.watch<T>()` ou `context.read<T>()`

## Rede

Abstração `AppNetwork` (interface) → `DioAppNetwork` (implementação):

- Timeouts configuráveis via `.env`
- Erros mapeados para `AppHttpException` / `AppNetworkException`
- Logs de debug via `AppDebugLog` (tags `SafeQR.Net`, `SafeQR.Reader`)

## Navegação

Navegação **imperativa** com `Navigator` + `MaterialPageRoute`. Sem `go_router` ou rotas nomeadas.

Ver detalhes em [09-navegacao-ui.md](./09-navegacao-ui.md).

## Integração com backend

O app consome a API em `safe_qr_back`. Em modo `remote`, o backend pode aplicar regras adicionais (ex.: blocklist Firestore de clones) que não existem no motor local.

Ver [07-api-integracao.md](./07-api-integracao.md).
