/// Garante tamanho mínimo e limite de caracteres (sem validação de conteúdo de negócio na S1).
final class ValidateQrPayload {
  const ValidateQrPayload();

  static const int _max = 2000;
  static const int _min = 1;

  /// [null] se ok; string amigável se inválido.
  String? call(String raw) {
    final t = raw.trim();
    if (t.length < _min) {
      return 'Introduza um conteúdo com pelo menos $_min caráter.';
    }
    if (t.length > _max) {
      return 'Conteúdo demasiado longo (máx. $_max).';
    }
    return null;
  }
}
