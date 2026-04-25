# Feature: QR scanner (análise)

- **Responsabilidade:** a câmera fica **sempre visível** na aba Ler; ao detectar um QR, abre-se uma **rota fullscreen** com o mesmo card **Analisando QR Code** (`SafeQrLoadingOverlay`), visível durante toda a análise. Em **`ANALYZE_MODE=remote`**, o tempo do loading = tempo real do `POST /v1/qr/analyze`; em **`local`**, mantém-se um mínimo de **3 s** em paralelo com a heurística. Depois, **push** da tela de resultado (Abrir destino / Permanecer no app / Copiar).
- **Plano (S1):** `ANALYZE_MODE=local` usa `QrLocalHeuristicEngine` (regras simples, sec. 2.3 do doc). `ANALYZE_MODE=remote` chama `POST /v1/qr/analyze` via `RemoteQrAnalyzeRepository` e `AppNetwork` (Dio abstraído).
- **Camadas:** `domain` (entidades, contratos, casos de uso), `data` (DTO, repositórios, motor local), `presentation` (ViewModel, páginas, widgets de UI).
- **Estado na UI:** `ChangeNotifier` com `package:provider`.
- **Testes:** `test/features/qr_scanner/qr_analyze_dto_test.dart`, `test/features/qr_scanner/qr_local_heuristic_engine_test.dart`.
