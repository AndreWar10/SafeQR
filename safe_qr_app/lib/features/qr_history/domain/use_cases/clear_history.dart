import '../repositories/history_repository.dart';

final class ClearHistory {
  const ClearHistory(this._repository);
  final HistoryRepository _repository;

  Future<void> call() => _repository.clear();
}
