# 14 — Guia de desenvolvimento

## Papel deste documento

Orientações para contribuir no `safe_qr_app` como engenheiro do serviço — convenções, fluxos de trabalho e pontos de extensão.

---

## Fluxo de trabalho típico

### Nova feature

1. Criar pasta em `lib/features/<nome>/` com camadas `domain/`, `data/`, `presentation/`
2. Adicionar README na feature (`lib/features/<nome>/README.md`)
3. Registrar dependências em `dependency_injection.dart`
4. Expor ViewModel via `MultiProvider` em `safe_qr_root.dart` (se necessário)
5. Adicionar testes em `test/features/<nome>/`
6. Atualizar documentação em `docs/`

### Alterar contrato da API

Ver checklist em [07-api-integracao.md](./07-api-integracao.md).

### Alterar heurísticas locais

Arquivo: `lib/features/qr_scanner/data/local/qr_local_heuristic_engine.dart`

Atualizar também:

- Testes em `qr_local_heuristic_engine_test.dart`
- Backend `QrAnalyzeService` (manter paridade local/remote)
- Documentação em [06-features.md](./06-features.md)

---

## Convenções de código

| Aspecto | Convenção |
|---------|-----------|
| Idioma UI | Português (pt-BR) em `AppStrings` |
| Idioma código | Inglês (nomes de classes, métodos) |
| Imutabilidade | `final class` para value objects e engines |
| Estado UI | `ChangeNotifier` + `provider` |
| Async | `Future` explícito; `unawaited` só para fire-and-forget debug |
| Erros de rede | Exceções tipadas (`AppHttpException`), não strings soltas |
| Logs | `AppDebugLog` com tags; sem `print` em produção |

### Estrutura de use case

```dart
final class AnalyzeQrCode {
  const AnalyzeQrCode(this._repo);
  final QrAnalyzeRepository _repo;

  Future<QrAnalysisResult> call(String raw, {String? appVersion, String? platform}) {
    return _repo.analyze(raw, appVersion: appVersion, platform: platform);
  }
}
```

### Estrutura de ViewModel

- Métodos públicos para ações da UI
- Getters para estado observável
- `notifyListeners()` após mudanças
- Tratamento de erro com mensagens de `AppStrings`

---

## Pontos de extensão

| Necessidade | Onde alterar |
|-------------|--------------|
| Novo tipo de QR gerado | `QrGenerationType`, `QrPayloadBuilder`, formulário em `QrGeneratorPage` |
| Nova heurística | `QrLocalHeuristicEngine` + backend |
| Novo endpoint | `AppEndpoints`, novo repositório, DI |
| Nova aba no shell | `MainShellPage` + novo widget na `IndexedStack` |
| Nova persistência | `AppDatabaseBootstrapper` (migration) ou novo repositório |
| Tema/cores | `AppTheme`, `AppColorTokens` |
| Strings | `AppStrings` |

---

## Debug

### Logs

```bash
adb logcat -s flutter
# ou filtrar SafeQR
adb logcat | findstr SafeQR
```

### Health probe

Com `ANALYZE_MODE=remote` em debug, o bootstrap loga:

```
Bootstrap: GET http://<url>/v1/health OK
```

ou falha com dica de IP.

### Hot reload

Funciona para UI e ViewModels. Alterações em:

- `dependency_injection.dart`
- `main.dart`
- Schema SQLite

requerem **hot restart** ou rebuild completo.

---

## Dependências — quando adicionar

1. Avaliar se o SDK Flutter já resolve
2. Adicionar em `pubspec.yaml`
3. `flutter pub get`
4. Documentar em [03-stack-tecnologica.md](./03-stack-tecnologica.md)
5. Configurar permissões nativas se necessário (Android/iOS)

---

## Branches e PRs (sugestão)

- `main` protegida
- Features em `feature/<nome>`
- PR com: descrição, screenshots (UI), testes passando
- Revisão entre membros do grupo

---

## Comandos úteis

```bash
# Dependências
flutter pub get

# Rodar
flutter run
flutter run -d <device_id>

# Testes e análise
flutter test
flutter analyze

# Limpar build
flutter clean && flutter pub get

# Listar dispositivos
flutter devices

# Gerar ícones (se configurado)
dart run flutter_launcher_icons
```

---

## Arquivos que todo dev deve conhecer

| Arquivo | Por quê |
|---------|---------|
| `lib/main.dart` | Bootstrap |
| `lib/app/di/dependency_injection.dart` | Wiring de tudo |
| `lib/app/safe_qr_root.dart` | Providers + MaterialApp |
| `lib/core/config/app_config.dart` | Config do .env |
| `assets/.env` | URL e modo de análise |
| `lib/core/constants/app_strings.dart` | Textos da UI |
| `lib/features/qr_scanner/data/local/qr_local_heuristic_engine.dart` | Regras de segurança |

---

## Anti-padrões a evitar

- Lógica de negócio diretamente em `build()` de widgets
- Chamadas Dio diretas nas páginas (usar repositório)
- Strings hardcoded na UI (usar `AppStrings`)
- Novos singletons globais fora do `get_it`
- Commitar `assets/.env` com IPs de produção ou secrets
