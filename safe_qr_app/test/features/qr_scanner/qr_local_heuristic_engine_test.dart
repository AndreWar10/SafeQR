import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/features/qr_scanner/data/local/qr_local_heuristic_engine.dart';
import 'package:safe_qr_app/features/qr_scanner/domain/entities/qr_security_verdict.dart';

void main() {
  const QrLocalHeuristicEngine e = QrLocalHeuristicEngine();

  test('https simples (sem sinais de risco) → safe', () {
    final r = e.evaluate('https://example.com/');
    expect(r.verdict, QrSecurityVerdict.safe);
    expect(r.safeToOpen, isTrue);
  });

  test('encurtador (bit.ly) → suspicious', () {
    final r = e.evaluate('https://bit.ly/abc');
    expect(r.verdict, QrSecurityVerdict.suspicious);
  });

  test('javascript: → unsafe', () {
    final r = e.evaluate('javascript:alert(1)');
    expect(r.verdict, QrSecurityVerdict.unsafe);
  });

  test('IP literal em host → suspicious (https)', () {
    final r = e.evaluate('https://192.0.2.1');
    expect(r.verdict, QrSecurityVerdict.suspicious);
  });
}
