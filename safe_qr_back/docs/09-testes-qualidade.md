# 09 — Testes e qualidade

## Suite de testes (Vitest)

**Comando:** `npm test`  
**Framework:** Vitest 3.x  
**Ambiente:** Node (sem browser)  
**Total:** 12 testes em 4 arquivos — **todos passando**

```
✓ test/suspicious-hosts-match.test.ts (3)
✓ test/qr-analyze-clones.test.ts (2)
✓ test/health.test.ts (2)
✓ test/qr-analyze.test.ts (5)
```

### Estrutura

```
test/
├── setup.ts                      # createTestApp() — Fastify injetado
├── health.test.ts                # GET /v1/health, GET /health
├── qr-analyze.test.ts            # Contrato POST /v1/qr/analyze
├── qr-analyze-clones.test.ts     # Service + mock blocklist
└── suspicious-hosts-match.test.ts # Funções puras de match
```

### Helper `createTestApp()`

Configura ambiente de teste isolado:

```typescript
loadEnv({
  NODE_ENV: 'test',
  LOG_LEVEL: 'fatal',           // silencia logs nos testes
  GOOGLE_APPLICATION_CREDENTIALS: '',
  FIREBASE_SERVICE_ACCOUNT_JSON: '',
});
```

Garante que testes **nunca** tentam conectar ao Firestore real.

### Técnica de teste HTTP

Usa `app.inject()` do Fastify — requisições in-process sem abrir porta TCP:

```typescript
const res = await app.inject({
  method: 'POST',
  url: '/v1/qr/analyze',
  payload: { rawContent: 'https://example.com/path' },
});
expect(res.statusCode).toBe(200);
```

## Cobertura por área

| Área | Coberto? | Arquivo |
|------|----------|---------|
| Health endpoints | ✅ | `health.test.ts` |
| Análise HTTPS safe | ✅ | `qr-analyze.test.ts` |
| Encurtador suspicious | ✅ | `qr-analyze.test.ts` |
| Esquema unsafe | ✅ | `qr-analyze.test.ts` |
| Validação 400 | ✅ | `qr-analyze.test.ts` |
| Payload 413 | ✅ | `qr-analyze.test.ts` |
| Blocklist mock | ✅ | `qr-analyze-clones.test.ts` |
| Normalização host | ✅ | `suspicious-hosts-match.test.ts` |
| Subdomínio blocklist | ✅ | `suspicious-hosts-match.test.ts` |
| Firestore real | ❌ | Requer credenciais |
| Error handler 500 | ❌ | Não testado |
| CORS headers | ❌ | Não testado |

## Lint e formatação

| Ferramenta | Comando | Config |
|------------|---------|--------|
| ESLint 9 (flat) | `npm run lint` | `eslint.config.mjs` |
| Prettier | `npm run format` | (padrão do projeto) |
| TypeScript strict | `npm run build` | `tsconfig.json` |

### TypeScript strict checks

- `noUnusedLocals`
- `noUnusedParameters`
- `noImplicitReturns`
- `noFallthroughCasesInSwitch`

## CI sugerido (GitHub Actions)

```yaml
name: safe-qr-back
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: safe_qr_back
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: npm
          cache-dependency-path: safe_qr_back/package-lock.json
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

## Boas práticas para novos testes

1. **Sempre** usar `createTestApp()` e `await app.close()` no fim
2. **Mock** portas externas (`SuspiciousHostsPort`) — nunca Firestore real no CI
3. Testar **contrato JSON** (campos, tipos, status codes)
4. Para novos endpoints, adicionar arquivo `test/<feature>.test.ts`
5. Testes de limite de env: instanciar `buildApp` com env customizado (ver teste 413)

## Gaps de teste (melhorias futuras)

- [ ] Teste de integração E2E com Firestore emulator
- [ ] Teste do error handler global (500)
- [ ] Teste de CORS preflight OPTIONS
- [ ] Snapshot dos formatos de erro
- [ ] Cobertura de código (`@vitest/coverage-v8`)
- [ ] Testes de carga (k6 ou autocannon) para RNF-03

## Qualidade de código — convenções

| Aspecto | Convenção |
|---------|-----------|
| Imports | Sufixo `.js` (ESM NodeNext) |
| Classes | PascalCase (`QrAnalyzeController`) |
| Arquivos | kebab-case (`qr-analyze.service.ts`) |
| Logs | Português nas mensagens humanas |
| API errors | Inglês nos códigos (`VALIDATION_ERROR`) |
| Comentários | Apenas onde a lógica não é óbvia |
