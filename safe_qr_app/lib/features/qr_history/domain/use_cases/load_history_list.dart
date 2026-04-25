import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

final class LoadHistoryList {
  const LoadHistoryList(this._repository);
  final HistoryRepository _repository;

  Future<List<HistoryItem>> call() => _repository.list();
}
