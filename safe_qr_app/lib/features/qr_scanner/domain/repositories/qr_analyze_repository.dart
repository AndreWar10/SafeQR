import '../entities/qr_security_verdict.dart';

abstract class QrAnalyzeRepository {
  Future<QrAnalysisResult> analyze(String rawContent, {String? appVersion, String? platform});
}
