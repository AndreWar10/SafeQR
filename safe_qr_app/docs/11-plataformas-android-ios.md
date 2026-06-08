# 11 — Plataformas (Android e iOS)

## Identificação do app

| Plataforma | Identificador | Nome exibido |
|------------|---------------|--------------|
| Android | `com.example.safe_qr_app` | Safe QR App |
| iOS | Bundle ID do projeto | Safe Qr App |

**Débito técnico:** package ID ainda usa prefixo `com.example` — alterar antes de publicação.

---

## Android

### Manifest (`android/app/src/main/AndroidManifest.xml`)

#### Permissões

| Permissão | Motivo |
|-----------|--------|
| `INTERNET` | Chamadas à API em modo remote |
| `CAMERA` | Leitura de QR codes |
| `WRITE_EXTERNAL_STORAGE` (maxSdk 29) | Salvar PNG na galeria (legado) |

#### Features

```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Câmera não obrigatória — app pode instalar em dispositivos sem câmera.

#### Configurações de rede

| Flag | Valor | Motivo |
|------|-------|--------|
| `usesCleartextTraffic` | `true` | HTTP local em desenvolvimento |
| `requestLegacyExternalStorage` | `true` | Compatibilidade galeria |

**Produção:** usar HTTPS e remover cleartext.

#### Queries (Android 11+)

Necessário para `url_launcher`:

- `PROCESS_TEXT`
- `VIEW` com schemes `http` e `https`

### Gradle

| Config | Valor |
|--------|-------|
| `minSdk` | 24 |
| `compileSdk` | Definido pelo Flutter |
| Google Services | Plugin aplicado (`google-services.json`) |
| Release signing | **Debug keys** (TODO) |

### Entry point

`android/app/src/main/kotlin/com/example/safe_qr_app/MainActivity.kt` — activity padrão Flutter.

---

## iOS

### Info.plist (`ios/Runner/Info.plist`)

#### Permissões (usage descriptions)

| Chave | Texto (resumo) |
|-------|----------------|
| `NSCameraUsageDescription` | Câmera para escanear QR |
| `NSPhotoLibraryAddUsageDescription` | Salvar QR na galeria |
| `NSPhotoLibraryUsageDescription` | Acesso à galeria para salvar/compartilhar |

#### URL schemes consultáveis

```xml
LSApplicationQueriesSchemes: https, http
```

Necessário para `url_launcher` abrir links externos.

#### Orientações

- iPhone: portrait + landscape
- iPad: todas as orientações padrão

---

## Firebase

### Inicialização

`main.dart`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Arquivos de configuração

| Plataforma | Arquivo |
|------------|---------|
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |
| Dart | `lib/firebase_options.dart` |

### Uso atual

| Pacote | Status |
|--------|--------|
| `firebase_core` | Inicializado no boot |
| `cloud_firestore` | Dependência declarada, **sem uso em código** |

Firestore no backend (`firebase-admin`) é usado para blocklist — não no app.

---

## Permissões em runtime

| Permissão | Pacote | Comportamento |
|-----------|--------|---------------|
| Câmera | `mobile_scanner` | Solicitada pelo plugin/SO ao abrir leitor |
| Galeria | `gal` | `Gal.requestAccess()` antes de salvar PNG |

O app define string `permissionCameraDenied` em `AppStrings`, mas não implementa fluxo dedicado de re-educação de permissão — depende do comportamento do plugin.

---

## Comportamento por plataforma

| Aspecto | Android | iOS | Web/Desktop |
|---------|---------|-----|-------------|
| Câmera | `mobile_scanner` | `mobile_scanner` | Limitado |
| Salvar galeria | `gal` | `gal` | N/A |
| Compartilhar | `share_plus` | `share_plus` | Variável |
| `platform` enviado à API | `android` | `ios` | `web` / `macos` / etc. |
| Cleartext HTTP | Permitido (dev) | ATS pode bloquear HTTP | Depende do browser |

### iOS — App Transport Security

Para desenvolvimento com HTTP local, pode ser necessário exceção ATS no `Info.plist` (não documentado no código atual — verificar se builds iOS falham com HTTP).

---

## Targets de release

| Plataforma | Prioridade S1 | Status |
|------------|---------------|--------|
| Android | Principal (Android first) | Funcional |
| iOS | Secundário | Configurado, requer conta Apple |
| Web | Experimental | Possível via `flutter run -d chrome` |
| Desktop | Não prioritário | Compila, câmera limitada |

Referência RNF-07: Android como alvo principal na Sprint 1.
