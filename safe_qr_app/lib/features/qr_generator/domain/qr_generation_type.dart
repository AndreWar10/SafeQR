/// Tipos de conteúdo comuns a codificar em QR (Sprint 1 — UX familiar).
enum QrGenerationType {
  /// Texto simples
  plainText,
  /// Página / link genérico
  url,
  /// URL de imagem (ficheiro) — ainda é texto; o QR não embute a imagem
  imageUrl,
  /// Rede sem fios
  wifi,
  /// Abrir o cliente de e-mail
  email,
  /// Ligar
  phone,
  /// SMS
  sms,
}
