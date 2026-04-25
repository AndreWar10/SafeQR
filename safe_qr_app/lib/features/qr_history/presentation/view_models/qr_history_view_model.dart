import 'package:flutter/foundation.dart';

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
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _deleteOne(id);
    await load();
  }

  Future<void> clear() async {
    await _clearAll();
    await load();
  }
}
