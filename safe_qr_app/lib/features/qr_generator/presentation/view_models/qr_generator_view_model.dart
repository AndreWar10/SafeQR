import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../qr_history/domain/entities/history_item.dart';
import '../../../qr_history/domain/use_cases/add_history_item.dart';
import '../../domain/qr_generation_type.dart';
import '../../domain/qr_payload_builder.dart';
import '../../domain/use_cases/validate_qr_payload.dart';

final class QrGeneratorViewModel extends ChangeNotifier {
  QrGeneratorViewModel({
    required AddHistoryItem addToHistory,
    required ValidateQrPayload validate,
    Uuid? uuid,
  })  : _addToHistory = addToHistory,
        _validate = validate,
        _uuid = uuid ?? const Uuid();

  final AddHistoryItem _addToHistory;
  final ValidateQrPayload _validate;
  final Uuid _uuid;

  QrGenerationType _type = QrGenerationType.plainText;
  String _draft = '';
  String _wifiSsid = '';
  String _wifiPassword = '';
  String _wifiSecurity = 'WPA';
  String _emailSubject = '';
  String _emailBody = '';
  String _smsText = '';

  String? _generatedPayload;
  String? _error;
  bool _saving = false;

  QrGenerationType get type => _type;
  String get draft => _draft;
  String get wifiSsid => _wifiSsid;
  String get wifiPassword => _wifiPassword;
  String get wifiSecurity => _wifiSecurity;
  String get emailSubject => _emailSubject;
  String get emailBody => _emailBody;
  String get smsText => _smsText;
  String? get generatedPayload => _generatedPayload;
  String? get error => _error;
  bool get isSaving => _saving;

  void setType(QrGenerationType t) {
    if (_type == t) {
      return;
    }
    _type = t;
    _generatedPayload = null;
    _error = null;
    notifyListeners();
  }

  void setDraft(String t) {
    if (_draft == t) {
      return;
    }
    _draft = t;
    notifyListeners();
  }

  void setWifiSsid(String v) {
    if (_wifiSsid == v) {
      return;
    }
    _wifiSsid = v;
    notifyListeners();
  }

  void setWifiPassword(String v) {
    if (_wifiPassword == v) {
      return;
    }
    _wifiPassword = v;
    notifyListeners();
  }

  void setWifiSecurity(String v) {
    if (_wifiSecurity == v) {
      return;
    }
    _wifiSecurity = v;
    notifyListeners();
  }

  void setEmailSubject(String v) {
    if (_emailSubject == v) {
      return;
    }
    _emailSubject = v;
    notifyListeners();
  }

  void setEmailBody(String v) {
    if (_emailBody == v) {
      return;
    }
    _emailBody = v;
    notifyListeners();
  }

  void setSmsText(String v) {
    if (_smsText == v) {
      return;
    }
    _smsText = v;
    notifyListeners();
  }

  void clearGenerated() {
    _generatedPayload = null;
    _error = null;
    notifyListeners();
  }

  /// Constrói o payload. Não gera nada se a validação falhar.
  void generateQr() {
    _error = null;
    final built = QrPayloadBuilder.build(
      type: _type,
      draft: _draft,
      wifiSsid: _wifiSsid,
      wifiPassword: _wifiPassword,
      wifiSecurity: _wifiSecurity,
      emailSubject: _emailSubject,
      emailBody: _emailBody,
      smsMessage: _smsText,
    );
    if (built == null) {
      _error = 'Preencha os campos obrigatórios deste tipo de QR.';
      _generatedPayload = null;
      notifyListeners();
      return;
    }
    final lengthError = _validate(built);
    if (lengthError != null) {
      _error = lengthError;
      _generatedPayload = null;
      notifyListeners();
      return;
    }
    _generatedPayload = built;
    notifyListeners();
  }

  Future<bool> saveToHistory() async {
    final payload = _generatedPayload;
    if (payload == null) {
      _error = 'Gere o QR Code antes de salvar.';
      notifyListeners();
      return false;
    }
    if (_saving) {
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final item = HistoryItem(
        id: _uuid.v4(),
        type: HistoryItemType.generated,
        content: payload,
        createdAt: DateTime.now(),
        verdict: null,
        safeToOpen: null,
        reasons: <String>['Tipo: ${_typeLabel(_type)}'],
      );
      await _addToHistory(item);
      return true;
    } on Object {
      _error = 'Falha ao salvar no histórico.';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  static String _typeLabel(QrGenerationType t) {
    return switch (t) {
      QrGenerationType.plainText => 'texto',
      QrGenerationType.url => 'url',
      QrGenerationType.imageUrl => 'imagem_url',
      QrGenerationType.wifi => 'wifi',
      QrGenerationType.email => 'email',
      QrGenerationType.phone => 'telefone',
      QrGenerationType.sms => 'sms',
    };
  }
}
