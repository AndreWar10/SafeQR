# 10 — Configuração e ambiente

## Pré-requisitos

| Ferramenta | Versão recomendada |
|------------|-------------------|
| Flutter SDK | >= 3.38.4 |
| Dart | ^3.11.4 |
| Android Studio / VS Code | Com extensão Flutter |
| Android SDK | minSdk 24 |
| Node.js (para backend) | 20 LTS+ (se usar modo remote) |

Verificar instalação:

```bash
flutter doctor -v
```

---

## Setup inicial

### 1. Clonar e entrar no projeto

```bash
cd safe-qr-mobile/safe_qr_app
```

### 2. Instalar dependências Flutter

```bash
flutter pub get
```

### 3. Configurar ambiente

Copiar template e editar:

```bash
cp assets/.env.example assets/.env
```

Conteúdo de referência (`assets/.env.example`):

```env
API_BASE_URL=http://10.0.2.2:3000
ANALYZE_MODE=remote
API_CONNECT_TIMEOUT_MS=20000
API_RECEIVE_TIMEOUT_MS=20000
THEME_PERSISTENCE_KEY=safe_qr_theme_mode
```

### 4. Firebase (opcional para S1)

O app inicializa `firebase_core` no boot. Arquivos necessários:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart` (gerado pelo FlutterFire CLI)

Firestore no app **não é usado** ainda — Firebase é principalmente para compatibilidade futura.

---

## Variáveis de ambiente

| Chave | Obrigatória | Default | Descrição |
|-------|-------------|---------|-----------|
| `API_BASE_URL` | Sim | — | URL base da API (sem `/` final) |
| `ANALYZE_MODE` | Não | `local` | `local` ou `remote`/`api`/`server` |
| `API_CONNECT_TIMEOUT_MS` | Não | `20000` | Timeout de conexão Dio (ms) |
| `API_RECEIVE_TIMEOUT_MS` | Não | `20000` | Timeout de resposta Dio (ms) |
| `THEME_PERSISTENCE_KEY` | Não | `safe_qr_theme_mode` | Chave SharedPreferences |

Leitura: `AppConfig.fromEnv()` em `lib/core/config/app_config.dart`

Chaves definidas em `lib/core/constants/app_env_keys.dart`

---

## Executar o app

### Modo local (sem backend)

```env
ANALYZE_MODE=local
```

```bash
flutter run
```

### Modo remote (com backend)

1. Subir API:

```bash
cd ../safe_qr_back
npm install
npm run dev
```

2. Configurar `API_BASE_URL` conforme dispositivo (ver tabela abaixo)

3. Executar:

```bash
cd ../safe_qr_app
flutter run
```

### Tabela de URLs

| Dispositivo | `API_BASE_URL` |
|-------------|----------------|
| Android Emulator | `http://10.0.2.2:3000` |
| Celular físico Android | `http://<IP-LAN>:3000` |
| iOS Simulator | `http://127.0.0.1:3000` |
| Chrome (web) | `http://127.0.0.1:3000` |

Descobrir IP no Windows: `ipconfig` → IPv4 da interface Wi-Fi/Ethernet.

---

## Build

### Debug APK (Android)

```bash
flutter build apk --debug
```

Saída: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

```bash
flutter build apk --release
```

**Atenção:** release Android ainda usa chaves de debug (TODO no `build.gradle.kts`).

### iOS

```bash
flutter build ios --release
```

Requer conta Apple Developer para deploy em dispositivo físico.

---

## Informações de versão

| Fonte | Valor |
|-------|-------|
| `pubspec.yaml` | `version: 1.0.0+1` |
| `AppBuildInfo.versionLabel` | `1.0.0` (manual) |
| `AppBuildInfo.buildNumber` | `1` (manual) |

Manter `AppBuildInfo` sincronizado com `pubspec.yaml` ao release.

---

## Logs de debug

Filtrar no Android logcat:

```bash
adb logcat | findstr SafeQR
```

Tags:

- `SafeQR.Net` — rede, health probe
- `SafeQR.Reader` — fluxo de scan

Em modo `remote` + debug, o bootstrap loga resultado do `GET /v1/health`.

---

## Troubleshooting

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| Scan → timeout | Backend inacessível | Verificar IP, firewall, `npm run dev` |
| `10.0.2.2` não funciona no físico | Host só existe no emulador | Usar IP LAN do PC |
| `Missing API_BASE_URL` | `.env` ausente ou vazio | Copiar `.env.example` |
| Câmera preta | Permissão negada | Conceder permissão nas configurações do SO |
| Cleartext HTTP bloqueado (release) | Android 9+ | Dev: `usesCleartextTraffic=true` no manifest; prod: HTTPS |

---

## CI sugerido

```yaml
# Exemplo de pipeline
- flutter pub get
- flutter analyze
- flutter test
- flutter build apk --debug
```

Artefato: APK debug para QA. Assinatura release em pipeline futuro.
