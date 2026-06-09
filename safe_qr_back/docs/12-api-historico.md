# 12 — API de Histórico (`/v1/history`)

Persiste na nuvem o mesmo que o app grava em SQLite local (`HistoryRepository`).

> O **mesmo contrato de auth** vale para `POST /v1/qr/analyze` — `FirebaseUserIdentityService` + `verifyIdToken`. Ver [05-api-endpoints.md](./05-api-endpoints.md#autenticação-v1qranalyze--v1history).

## Autenticação (obrigatória)

Todos os endpoints de histórico exigem:

```
Authorization: Bearer <Firebase ID Token>
```

| Passo | Onde |
|-------|------|
| 1. App obtém JWT | `await FirebaseAuth.instance.currentUser!.getIdToken()` |
| 2. App envia header | `Authorization: Bearer <JWT>` |
| 3. Back valida | `firebase-admin` → `verifyIdToken(token)` |
| 4. Back identifica user | `decoded.uid` → `idUser` |

| O que enviar | Válido? |
|--------------|---------|
| Firebase ID Token (JWT, `eyJ…`) | ✅ |
| UID (`Vb3ubOjy9RYt9AKpx3VzunBirEc2`) no Bearer | ❌ |
| `client.idUser` no body | ❌ não autentica |

**Requisito servidor:** `GOOGLE_APPLICATION_CREDENTIALS` ou `FIREBASE_SERVICE_ACCOUNT_JSON` (mesmo projeto Firebase do app).

---

## Modelo Firestore

```
history                              ← coleção
 └── {idUser}                        ← doc = UID do Firebase Auth
      └── items                       ← subcoleção
           └── {id}                    ← doc = UUID do item (app)
```

Exemplo real:

```
history/Vb3ubOjy9RYt9AKpx3VzunBirEc2/items/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

O documento `history/{idUser}` é criado automaticamente no primeiro POST.

---

## Modelo — `HistoryItem`

| Campo JSON | Tipo | Obrigatório | Notas |
|------------|------|-------------|-------|
| `id` | string (UUID) | Sim | Gerado no app (`uuid.v4()`) |
| `type` | enum | Sim | `"scan"` \| `"generated"` |
| `content` | string | Sim | Max 2000 chars → `413` |
| `createdAtMs` | integer | Sim | Epoch ms |
| `verdict` | string \| null | Condicional | Obrigatório se `type=scan` |
| `safeToOpen` | boolean \| null | Condicional | Obrigatório se `type=scan` |
| `reasons` | string[] | Sim | Max 50 × 500 chars |

### `verdict` (só `scan`)

`safe` \| `suspicious` \| `unsafe` \| `unknown`

### `generated`

`verdict` e `safeToOpen` devem ser `null`. Ex.: `reasons: ["Tipo: wifi"]`

---

## Endpoints

| Método | Path | Operação SQLite |
|--------|------|-----------------|
| `POST` | `/v1/history` | `add()` upsert |
| `GET` | `/v1/history` | `list()` DESC |
| `DELETE` | `/v1/history/{id}` | `deleteById()` |
| `DELETE` | `/v1/history` | `clear()` |

---

## Exemplos

### POST — scan

```http
POST /v1/history HTTP/1.1
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...

{
  "item": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "type": "scan",
    "content": "https://example.com/path",
    "createdAtMs": 1717689600123,
    "verdict": "suspicious",
    "safeToOpen": false,
    "reasons": ["URL usa redirecionador conhecido..."]
  },
  "client": { "appVersion": "1.0.0", "platform": "android" }
}
```

**201:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "idUser": "Vb3ubOjy9RYt9AKpx3VzunBirEc2",
  "savedAt": "2026-06-08T12:00:00.123Z"
}
```

### POST — generated

```json
{
  "item": {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "type": "generated",
    "content": "WIFI:T:WPA;S:MinhaRede;P:senha123;;",
    "createdAtMs": 1717689700456,
    "verdict": null,
    "safeToOpen": null,
    "reasons": ["Tipo: wifi"]
  },
  "client": { "appVersion": "1.0.0", "platform": "android" }
}
```

### GET — listar

```http
GET /v1/history?limit=100&offset=0 HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**200:**
```json
{
  "items": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "type": "scan",
      "content": "https://example.com/path",
      "createdAtMs": 1717689600123,
      "verdict": "suspicious",
      "safeToOpen": false,
      "reasons": ["URL usa redirecionador conhecido..."]
    }
  ],
  "total": 1
}
```

### DELETE — um item

```http
DELETE /v1/history/a1b2c3d4-e5f6-7890-abcd-ef1234567890 HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

→ `204`

### DELETE — limpar tudo

```http
DELETE /v1/history HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

→ `204`

---

## Erros

| Status | Quando |
|--------|--------|
| `400` | Validação Zod |
| `401` | Bearer ausente ou JWT inválido/expirado |
| `404` | Item não existe ou não é do user |
| `413` | `content` > 2000 chars |
| `503` | Servidor sem credenciais Firebase |

---

## Integração Flutter

O app usa `RemoteHistoryRepository` com `AuthenticatedAppNetwork` — Bearer injetado automaticamente (mesmo padrão do analyze).

```dart
// dependency_injection.dart
registerLazySingleton<AppNetwork>(
  () => AuthenticatedAppNetwork(inner: DioAppNetwork(dio: sl()), identity: sl()),
);

// RemoteHistoryRepository — sem header manual
await _net.post(
  AppEndpoints.history,
  body: {
    'item': HistoryApiMapper.itemToApiJson(item),
    'client': {'appVersion': '1.0.0', 'platform': 'android'},
  },
);
```

Ver também: [`safe_qr_app/docs/07-api-integracao.md`](../../safe_qr_app/docs/07-api-integracao.md).

---

## Código-fonte

| Arquivo | Papel |
|---------|-------|
| `src/schemas/history.schema.ts` | Zod |
| `src/controllers/history.controller.ts` | HTTP |
| `src/services/history-firestore.repository.ts` | Firestore `history/{uid}/items/{id}` |
| `src/services/firebase-user-identity.service.ts` | `verifyIdToken` |
| `test/history.test.ts` | 15 testes |
