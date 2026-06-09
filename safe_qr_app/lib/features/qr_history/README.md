# Feature: Histórico

- **Responsabilidade:** listar leituras e QR gerados, apagar item ou limpar tudo.
- **Modo remoto (`ANALYZE_MODE=remote`):**
  - **Scans:** gravados **assincronamente** via Pub/Sub → `consume:history` → Firestore `history/{uid}/items/{id}`. O app **não** faz POST ao escanear — só `POST /v1/qr/analyze` com Bearer.
  - **Leitura:** `GET /v1/history` com Bearer JWT (pull-to-refresh na UI).
  - **QR gerados:** ainda usam `POST /v1/history` ao salvar no gerador.
- **Modo local:** SQLite no aparelho (`HistoryRepositoryImpl`).
- **Consistência eventual:** após scan, o item pode demorar 1–3s a aparecer no histórico (fila + consumidor).
- **Camadas:** `domain`, `data` (`RemoteHistoryRepository` / `HistoryRepositoryImpl`), `presentation`.
- **Testes:** `test/features/qr_history/`.

Ver também: `safe_qr_messaging/docs/02-FANOUT-HISTORICO-AUDIT.md`, `safe_qr_back/docs/12-api-historico.md`.
