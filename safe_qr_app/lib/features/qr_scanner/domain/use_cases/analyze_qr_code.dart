import '../entities/qr_security_verdict.dart';
import '../repositories/qr_analyze_repository.dart';

final class AnalyzeQrCode {
  const AnalyzeQrCode(this._repository);
  final QrAnalyzeRepository _repository;

  Future<QrAnalysisResult> call(
    String raw, {
    String? appVersion,
    String? platform,
  }) {
    return _repository.analyze(raw, appVersion: appVersion, platform: platform);
  }
}
