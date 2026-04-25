# Dados, privacidade (mobile) — alinhado ao RNF-02 (Sprint 1)

## O que o app envia

- **Modo `ANALYZE_MODE=remote`:** o conteúdo bruto lido do QR (string) é enviado no corpo de `POST /v1/qr/analyze`, com metadados mínimos de cliente (`appVersion`, `plataforma`) — conforme o contrato do planeamento.
- **Modo `ANALYZE_MODE=local`:** **nada** do QR é enviado a um servidor. A análise é heurística no aparelho (limitações descritas na app).

## O que fica no aparelho

- **Histórico:** leituras (com metadados de veredicto/razões quando houver) e QR gerados, em base local (`sqflite`).

## O que o app não inclui (S1)

- Conta de utilizador, login, ou armazenamento de dados sensíveis fora do que o utilizador vê (histórico local).

## Evolução (LGPD / remoto)

- Quando a API estiver ativa, documente no backend o tratamento, base legal e retenção; o mobile deve acompanhar políticas e consentimentos, se exigido pelo curso.
