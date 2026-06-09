import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Pseudónimo local estável enviado à API como `client.idUser`.
final class UserIdentityService {
  UserIdentityService(this._prefs, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String persistenceKey = 'safe_qr_id_user';

  final SharedPreferences _prefs;
  final Uuid _uuid;

  Future<String> getOrCreateIdUser() async {
    final String? existing = _prefs.getString(persistenceKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String created = 'usr_${_uuid.v4()}';
    await _prefs.setString(persistenceKey, created);
    return created;
  }
}
