import '../entities/history_item.dart';

abstract class HistoryRepository {
  Future<void> add(HistoryItem item);
  Future<List<HistoryItem>> list();
  Future<void> deleteById(String id);
  Future<void> clear();
}
