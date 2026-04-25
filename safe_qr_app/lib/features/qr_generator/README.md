# Feature: Gerador de QR

- **Responsabilidade:** o usuário escolhe o **tipo** (texto, URL, imagem por link, Wi‑Fi, e-mail, telefone, SMS), preenche e toca em **«Gerar QR Code»**. Ao gerar (após validação), mostra-se **2 segundos** de overlay «Gerando QR Code» e, em seguida, o **payload** é **salvo no histórico (SQLite)** e abre uma **nova tela** com o QR, com duas ações: **Salvar no dispositivo** (imagem na galeria, via `gal` e permissões) e **Compartilhar** (ficha nativa com PNG). O QR **não contém arquivos binários** (ex.: `.jpg` embutido): «imagem» = **URL** que aponta para a imagem.
- **Camadas:** `domain` (`QrGenerationType`, `QrPayloadBuilder`, validação de tamanho), `presentation` (ViewModel + `QrGeneratorPage` + `QrGeneratorResultPage`, `QrPngBytes` para exportar PNG), overlay de espera em `shared` (`SafeQrLoadingOverlay`).
- **Estado na UI:** `ChangeNotifier` + `TextEditingController` na página (o formulário não mostra pré-visualização do QR; o resultado fica no push).
- **Testes:** `test/features/qr_generator/validate_qr_payload_test.dart`, `test/features/qr_generator/qr_payload_builder_test.dart`.
