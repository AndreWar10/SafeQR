import 'qr_generation_type.dart';

/// Constrói a string exata alimentada ao [QrImageView] a partir do tipo e campos.
final class QrPayloadBuilder {
  const QrPayloadBuilder._();

  /// Devolve `null` se faltar dado essencial; caso contrário a string a codificar.
  static String? build({
    required QrGenerationType type,
    required String draft,
    String wifiSsid = '',
    String wifiPassword = '',
    String wifiSecurity = 'WPA',
    String emailSubject = '',
    String emailBody = '',
    String smsMessage = '',
  }) {
    switch (type) {
      case QrGenerationType.plainText:
        final t = draft.trim();
        return t.isEmpty ? null : t;
      case QrGenerationType.url:
        return _urlPayload(draft);
      case QrGenerationType.imageUrl:
        return _urlPayload(draft);
      case QrGenerationType.wifi:
        return _wifiPayload(
          ssid: wifiSsid,
          password: wifiPassword,
          security: wifiSecurity,
        );
      case QrGenerationType.email:
        return _mailto(draft, emailSubject, emailBody);
      case QrGenerationType.phone:
        return _tel(draft);
      case QrGenerationType.sms:
        return _sms(draft, smsMessage);
    }
  }

  static String? _urlPayload(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return null;
    }
    if (t.contains('://')) {
      return t;
    }
    return 'https://$t';
  }

  static String? _mailto(String address, String subject, String body) {
    final a = address.trim();
    if (a.isEmpty || !a.contains('@')) {
      return null;
    }
    final q = <String, String>{};
    final s = subject.trim();
    final b = body.trim();
    if (s.isNotEmpty) {
      q['subject'] = s;
    }
    if (b.isNotEmpty) {
      q['body'] = b;
    }
    return Uri(
      scheme: 'mailto',
      path: a,
      queryParameters: q.isEmpty ? null : q,
    ).toString();
  }

  static String? _tel(String raw) {
    var t = raw.trim();
    if (t.isEmpty) {
      return null;
    }
    if (t.toLowerCase().startsWith('tel:')) {
      return t;
    }
    t = t.replaceAll(' ', '');
    return 'tel:$t';
  }

  static String? _sms(String numberRaw, String message) {
    var n = numberRaw.trim();
    if (n.isEmpty) {
      return null;
    }
    if (n.toLowerCase().startsWith('sms:')) {
      n = n.substring(4);
    }
    n = n.replaceAll(' ', '');
    final m = message.trim();
    if (m.isEmpty) {
      return 'sms:$n';
    }
    return 'sms:$n?${Uri(queryParameters: <String, String>{'body': m}).query}';
  }

  /// Formato comum: `WIFI:T:WPA;S:ssid;P:pass;;`
  static String? _wifiPayload({
    required String ssid,
    required String password,
    required String security,
  }) {
    final s = ssid.trim();
    if (s.isEmpty) {
      return null;
    }
    final sec = _normalizeSecurity(security);
    return 'WIFI:T:$sec;S:${_escape(s)};P:${_escape(password)};;';
  }

  static String _normalizeSecurity(String s) {
    final u = s.trim().toUpperCase();
    if (u == 'WPA' || u == 'WPA2' || u == 'WEP' || u == 'NOPASS') {
      if (u == 'WPA2') {
        return 'WPA';
      }
      return u;
    }
    return 'WPA';
  }

  static String _escape(String s) {
    return s
        .replaceAll('\\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:');
  }
}
