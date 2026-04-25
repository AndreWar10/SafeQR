import '../repositories/history_repository.dart';

final class DeleteHistoryItem {
  const DeleteHistoryItem(this._repository);
  final HistoryRepository _repository;

  Future<void> call(String id) => _repository.deleteById(id);
}
