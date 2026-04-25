import '../../domain/entities/qr_security_verdict.dart';
import '../models/qr_analyze_dto.dart';

final class QrAnalysisMappers {
  const QrAnalysisMappers._();

  static QrAnalysisResult toDomain(QrAnalyzeDto dto) {
    return QrAnalysisResult(
      requestId: dto.requestId,
      verdict: _mapVerdict(dto.verdict),
      safeToOpen: dto.safeToOpen,
      reasons: dto.reasons,
      parsed: dto.parsed == null
          ? null
          : QrParsedSummary(
              type: dto.parsed!.type,
              scheme: dto.parsed!.scheme,
              host: dto.parsed!.host,
            ),
    );
  }

  static QrSecurityVerdict _mapVerdict(String v) {
    final s = v.toLowerCase();
    if (s == 'safe') return QrSecurityVerdict.safe;
    if (s == 'suspicious' || s == 'suspect') return QrSecurityVerdict.suspicious;
    if (s == 'unsafe' || s == 'danger' || s == 'malicious') return QrSecurityVerdict.unsafe;
    return QrSecurityVerdict.unknown;
  }
}
