# 04 — Estrutura do projeto

## Árvore de diretórios (`lib/`)

```
lib/
├── main.dart                          # Entry point
├── firebase_options.dart              # Config FlutterFire
│
├── app/
│   ├── app_initializer.dart           # Bootstrap (Firebase, DI, identidade)
│   ├── app_routes.dart                # Rotas nomeadas
│   ├── safe_qr_root.dart              # MultiProvider + MaterialApp
│   └── di/
│       └── dependency_injection.dart  # Registro get_it
│
├── core/
│   ├── identity/
│   │   ├── user_identity_repository.dart
│   │   ├── firebase_anonymous_user_identity_repository.dart
│   │   ├── user_identity_service.dart
│   │   └── user_identity_exception.dart
│   ├── config/
│   │   ├── app_config.dart            # Leitura do .env
│   │   ├── analyze_mode.dart          # enum local | remote
│   │   └── app_build_info.dart        # versionLabel, buildNumber
│   ├── constants/
│   │   ├── app_strings.dart           # Strings pt-BR da UI
│   │   ├── app_endpoints.dart         # /v1/health, /v1/qr/analyze
│   │   ├── app_env_keys.dart          # Chaves do .env
│   │   └── app_assets.dart            # Caminhos de assets
│   ├── database/
│   │   ├── app_database_bootstrapper.dart
│   │   └── app_database_names.dart    # Nome do arquivo, schema version
│   ├── logging/
│   │   └── app_debug_log.dart         # Logs tagueados (debug)
│   ├── network/
│   │   ├── app_network.dart           # Interface abstrata
│   │   ├── dio_app_network.dart       # Implementação Dio
│   │   └── app_network_exception.dart # Exceções HTTP/rede
│   └── theme/
│       ├── app_theme.dart             # Material 3 light/dark
│       ├── app_color_tokens.dart      # Tokens de cor
│       └── app_theme_mode_controller.dart
│
├── features/
│   ├── splash/
│   │   └── presentation/pages/splash_page.dart
│   ├── shell/
│   │   └── presentation/pages/main_shell_page.dart
│   ├── qr_scanner/
│   │   ├── domain/
│   │   │   ├── entities/              # QrAnalysisResult, QrSecurityVerdict
│   │   │   ├── repositories/          # QrAnalyzeRepository (contrato)
│   │   │   └── use_cases/             # AnalyzeQrCode
│   │   ├── data/
│   │   │   ├── local/                 # QrLocalHeuristicEngine
│   │   │   ├── models/                # QrAnalyzeDto
│   │   │   ├── mappers/               # QrAnalysisMappers
│   │   │   └── repositories/          # Local + Remote implementations
│   │   └── presentation/
│   │       ├── pages/                 # QrReaderPage, ScanResultPage
│   │       ├── view_models/           # QrReaderViewModel
│   │       ├── widgets/               # VerdictBadge
│   │       └── utils/                 # verdict_presentation
│   ├── qr_generator/
│   │   ├── domain/
│   │   │   ├── qr_generation_type.dart
│   │   │   ├── qr_payload_builder.dart
│   │   │   └── use_cases/validate_qr_payload.dart
│   │   └── presentation/
│   │       ├── pages/                 # QrGeneratorPage, QrGeneratorResultPage
│   │       ├── view_models/           # QrGeneratorViewModel
│   │       └── util/                  # QrPngBytes
│   └── qr_history/
│       ├── domain/
│       │   ├── entities/history_item.dart
│       │   ├── repositories/history_repository.dart
│       │   └── use_cases/             # add, load, delete, clear
│       ├── data/
│       │   ├── history_data_mapper.dart
│       │   └── repositories/history_repository_impl.dart
│       └── presentation/
│           ├── pages/qr_history_page.dart
│           └── view_models/qr_history_view_model.dart
│
└── shared/
    └── presentation/widgets/
        ├── safe_qr_loading_overlay.dart
        ├── app_hero_header.dart
        ├── app_rounded_action_button.dart
        ├── app_busy_overlay.dart
        └── theme_cycle_action.dart
```

## Outras pastas relevantes

```
safe_qr_app/
├── assets/
│   ├── .env              # Config runtime (não commitar secrets)
│   └── .env.example      # Template documentado
├── android/              # Manifest, Gradle, permissões
├── ios/                  # Info.plist, permissões
├── test/                 # Testes unitários e smoke
└── docs/                 # Esta documentação
```

## Convenções de nomenclatura

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Páginas | `*_page.dart` | `QrReaderPage` |
| ViewModels | `*_view_model.dart` | `QrReaderViewModel` |
| Repositórios (contrato) | `*_repository.dart` | `QrAnalyzeRepository` |
| Repositórios (impl) | `*_repository_impl.dart` ou prefixo descritivo | `RemoteQrAnalyzeRepository` |
| Use cases | verbo em snake_case | `analyze_qr_code.dart` |
| DTOs | `*_dto.dart` | `QrAnalyzeDto` |
| Mappers | `*_mappers.dart` ou `*_data_mapper.dart` | `QrAnalysisMappers` |
| Entidades | substantivo | `HistoryItem`, `QrAnalysisResult` |
| Classes finais | `final class` quando imutável | `AppConfig`, `QrLocalHeuristicEngine` |

## READMEs por feature

Cada feature em `lib/features/*/README.md` documenta:

- Responsabilidade da feature
- Camadas e componentes
- Comportamento de UI
- Testes associados

## Testes espelhados

```
test/features/<feature>/<arquivo>_test.dart
```

Espelha a estrutura de `lib/features/`.

## Assets

Declarados em `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/
    - assets/.env
```

O `.env` é empacotado no bundle — em produção, considerar flavors ou `--dart-define` para não expor URLs de dev.
