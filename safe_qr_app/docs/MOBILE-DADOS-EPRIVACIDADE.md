# Dados, privacidade (mobile) — alinhado ao RNF-02 (Sprint 1)

> Documentação expandida: [12-seguranca-privacidade.md](./12-seguranca-privacidade.md)

## O que o app envia

- **Modo `ANALYZE_MODE=remote`:** o conteúdo bruto lido do QR (string) é enviado no corpo de `POST /v1/qr/analyze`, com metadados mínimos de cliente (`appVersion`, `plataforma`, `idUser`) — conforme o contrato do planeamento.
- **`idUser`:** UID de **Firebase Anonymous Auth** (pseudónimo técnico por instalação; sem e-mail nem palavra-passe). Ver [17-identidade-firebase-anonymous.md](./17-identidade-firebase-anonymous.md).
- **Modo `ANALYZE_MODE=local`:** **nada** do QR é enviado a um servidor. A análise é heurística no aparelho (limitações descritas na app).

## O que fica no aparelho

- **Histórico:** leituras (com metadados de veredicto/razões quando houver) e QR gerados, em base local (`sqflite`).

## O que o app não inclui (S1)

- Conta com e-mail/palavra-passe ou dados sensíveis fora do que o utilizador vê (histórico local). *Sessão anónima Firebase não é “login” visível ao utilizador.*

## Evolução (LGPD / remoto)

- Quando a API estiver ativa, documente no backend o tratamento, base legal e retenção; o mobile deve acompanhar políticas e consentimentos, se exigido pelo curso.
