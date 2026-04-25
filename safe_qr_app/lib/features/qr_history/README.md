# Feature: Histórico

- **Responsabilidade:** persistir leituras (com metadados de análise) e QR gerados, listar, apagar e limpar tudo, localmente (SQLite vía `sqflite`).
- **Camadas:** `domain` (entidade `HistoryItem`, repositório abstrato, casos de uso), `data` (tabela, mapeador, repositório concreto), `presentation` (ViewModel, lista, modais).
- **Estado na UI:** `ChangeNotifier` e refresh/pull-to-refresh.
- **Testes:** `test/features/qr_history/history_data_mapper_test.dart`.
