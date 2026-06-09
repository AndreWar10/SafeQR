import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/app_network_exception.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/use_cases/clear_history.dart';
import '../../domain/use_cases/delete_history_item.dart';
import '../../domain/use_cases/load_history_list.dart';

final class QrHistoryViewModel extends ChangeNotifier {
  QrHistoryViewModel({
    required LoadHistoryList load,
    required DeleteHistoryItem deleteOne,
    required ClearHistory clearAll,
  })  : _load = load,
        _deleteOne = deleteOne,
        _clearAll = clearAll;

  final LoadHistoryList _load;
  final DeleteHistoryItem _deleteOne;
  final ClearHistory _clearAll;

  List<HistoryItem> _items = <HistoryItem>[];
  bool _loading = true;
  String? _error;

  List<HistoryItem> get items => List<HistoryItem>.unmodifiable(_items);
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _load();
    } on AppHttpException catch (e) {
      _error = _httpErrorLabel(e);
    } on AppNetworkException catch (e) {
      _error = e.message;
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> removeMany(Iterable<String> ids) async {
    final List<String> unique = ids.toSet().toList(growable: false);
    if (unique.isEmpty) {
      return;
    }
    for (final String id in unique) {
      await remove(id);
      if (_error != null) {
        return;
      }
    }
  }

  Future<void> remove(String id) async {
    _error = null;
    try {
      await _deleteOne(id);
      _items = _items.where((HistoryItem i) => i.id != id).toList(growable: false);
      notifyListeners();
    } on AppHttpException catch (e) {
      if (e.statusCode == 404) {
        _items = _items.where((HistoryItem i) => i.id != id).toList(growable: false);
      }
      _error = e.statusCode == 404 ? 'Item já não existe.' : AppStrings.historyDeleteFailed;
      notifyListeners();
    } on AppNetworkException catch (e) {
      _error = e.message;
      notifyListeners();
    } on Object {
      _error = AppStrings.historyDeleteFailed;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _error = null;
    notifyListeners();
    try {
      await _clearAll();
      _items = const <HistoryItem>[];
      notifyListeners();
    } on AppHttpException catch (e) {
      _error = _httpErrorLabel(e, fallback: AppStrings.historyClearFailed);
      notifyListeners();
    } on AppNetworkException catch (e) {
      _error = e.message;
      notifyListeners();
    } on Object {
      _error = AppStrings.historyClearFailed;
      notifyListeners();
    }
  }

  static String _httpErrorLabel(AppHttpException e, {String fallback = AppStrings.networkError}) {
    if (e.statusCode == 401) {
      return AppStrings.identityError;
    }
    if (kDebugMode && e.message.isNotEmpty) {
      return '$fallback (${e.statusCode ?? '—'}: ${e.message})';
    }
    return fallback;
  }
}
