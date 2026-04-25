import '../../domain/entities/qr_security_verdict.dart';
import '../../domain/repositories/qr_analyze_repository.dart';
import '../local/qr_local_heuristic_engine.dart';

/// Análise alinhada ao contrato (mesmo DTO/result no domínio) sem chamar a API (S1 / backend indisponível).
final class LocalHeuristicQrAnalyzeRepository implements QrAnalyzeRepository {
  const LocalHeuristicQrAnalyzeRepository(this._engine);
  final QrLocalHeuristicEngine _engine;

  @override
  Future<QrAnalysisResult> analyze(
    String rawContent, {
    String? appVersion,
    String? platform,
  }) async {
    // Simula a latência mínima (RNF-03) sem bloquear a UI desnecessariamente.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _engine.evaluate(rawContent);
  }
}
