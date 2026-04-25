import 'package:equatable/equatable.dart';

enum HistoryItemType { scan, generated }

class HistoryItem extends Equatable {
  const HistoryItem({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.verdict,
    this.safeToOpen,
    this.reasons = const <String>[],
  });

  final String id;
  final HistoryItemType type;
  final String content;
  final DateTime createdAt;
  final String? verdict;
  final bool? safeToOpen;
  final List<String> reasons;

  @override
  List<Object?> get props => [id, type, content, createdAt, verdict, safeToOpen, reasons];
}
