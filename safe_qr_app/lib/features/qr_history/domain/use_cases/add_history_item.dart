import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

/// [Single Responsibility] — adiciona um registo ao repositório.
final class AddHistoryItem {
  const AddHistoryItem(this._repository);
  final HistoryRepository _repository;

  Future<void> call(HistoryItem item) => _repository.add(item);
}
