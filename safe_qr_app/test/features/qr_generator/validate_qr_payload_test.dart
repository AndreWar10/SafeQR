import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/features/qr_generator/domain/use_cases/validate_qr_payload.dart';

void main() {
  const ValidateQrPayload v = ValidateQrPayload();

  test('rejeita vazio / só espaços', () {
    expect(v(''), isNotNull);
    expect(v('   '), isNotNull);
  });

  test('aceita texto curto', () {
    expect(v('a'), isNull);
  });
}
