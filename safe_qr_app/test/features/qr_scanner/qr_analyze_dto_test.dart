import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/features/qr_scanner/data/models/qr_analyze_dto.dart';
import 'package:safe_qr_app/features/qr_scanner/data/mappers/qr_analysis_mappers.dart';
import 'package:safe_qr_app/features/qr_scanner/domain/entities/qr_security_verdict.dart';

void main() {
  test('fromJson mapeia campos camelCase e converte em domínio', () {
    final dto = QrAnalyzeDto.fromJson(<String, Object?>{
      'requestId': 'rid',
      'verdict': 'suspicious',
      'safeToOpen': false,
      'reasons': <String>['A', 'B'],
      'parsed': <String, Object?>{'type': 'url', 'scheme': 'https', 'host': 'x.com'},
    });

    expect(dto.requestId, 'rid');
    final domain = QrAnalysisMappers.toDomain(dto);
    expect(domain.verdict, QrSecurityVerdict.suspicious);
    expect(domain.parsed?.host, 'x.com');
  });
}
