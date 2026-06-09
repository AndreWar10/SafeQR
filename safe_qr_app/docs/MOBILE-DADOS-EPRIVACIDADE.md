# Dados, privacidade (mobile) — alinhado ao RNF-02 (Sprint 1)

> Documentação expandida: [12-seguranca-privacidade.md](./12-seguranca-privacidade.md)

## O que o app envia

- **Modo `ANALYZE_MODE=remote`:**
  - `POST /v1/qr/analyze` — conteúdo bruto do QR + `client.appVersion` / `client.platform`
  - `GET` / `DELETE` `/v1/history` — listar e apagar histórico
  - `POST /v1/history` — QR gerado (ao salvar no gerador)
  - Todos os pedidos ao back incluem `Authorization: Bearer <Firebase ID Token>`
- **Identidade:** UID via JWT (Firebase Anonymous Auth). **Não** enviar UID no body do analyze.
- **Modo `ANALYZE_MODE=local`:** **nada** do QR é enviado a um servidor.

Ver [17-identidade-firebase-anonymous.md](./17-identidade-firebase-anonymous.md).

## O que fica no aparelho

| Dado | Modo local | Modo remote |
|------|------------|-------------|
| Histórico de scans | SQLite | Nuvem (Firestore via API) |
| Histórico de QR gerados | SQLite | Nuvem (se salvo no gerador) |
| Preferência de tema | `SharedPreferences` (`light` / `dark`) | Igual |
| Sessão Firebase | SDK (UID anónimo) | Igual |

## O que o app não inclui (S1)

- Conta com e-mail/palavra-passe visível ao utilizador
- Analytics de terceiros (Firebase Analytics não configurado)
- Leitura/escrita direta Firestore no mobile (`cloud_firestore` não usado em `lib/`)

## Evolução (LGPD)

- Documentar no backend tratamento, base legal e retenção do histórico na nuvem
- Política de privacidade deve mencionar pseudónimo Firebase e conteúdo de QR enviado para análise
