import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/features/qr_generator/domain/qr_generation_type.dart';
import 'package:safe_qr_app/features/qr_generator/domain/qr_payload_builder.dart';

void main() {
  test('texto: trim', () {
    expect(
      QrPayloadBuilder.build(type: QrGenerationType.plainText, draft: '  a  '),
      'a',
    );
  });

  test('url: adiciona https se faltar o esquema', () {
    expect(
      QrPayloadBuilder.build(type: QrGenerationType.url, draft: 'exemplo.com'),
      'https://exemplo.com',
    );
  });

  test('wifi: SSID mínimo', () {
    final s = QrPayloadBuilder.build(
      type: QrGenerationType.wifi,
      draft: '',
      wifiSsid: ' MinhaRede ',
      wifiPassword: 'p',
      wifiSecurity: 'WPA',
    );
    expect(s, isNotNull);
    expect(s, startsWith('WIFI:'));
  });

  test('e-mail: mailto com assunto e corpo', () {
    final s = QrPayloadBuilder.build(
      type: QrGenerationType.email,
      draft: 'a@b.com',
      emailSubject: 'Olá',
      emailBody: 'Teste',
    );
    expect(s, isNotNull);
    expect(s, startsWith('mailto:a@b.com'));
    expect(s, contains('body='));
  });

  test('telefone: adiciona tel:', () {
    expect(
      QrPayloadBuilder.build(type: QrGenerationType.phone, draft: ' +351 911 '),
      'tel:+351911',
    );
  });

  test('SMS: corpo em query', () {
    final s = QrPayloadBuilder.build(
      type: QrGenerationType.sms,
      draft: '+1999',
      smsMessage: 'oi',
    );
    expect(s, isNotNull);
    expect(s, startsWith('sms:+1999?'));
  });

  test('imagem: mesmo pipeline que url', () {
    expect(
      QrPayloadBuilder.build(type: QrGenerationType.imageUrl, draft: 'cdn.org/x.png'),
      'https://cdn.org/x.png',
    );
  });
}
