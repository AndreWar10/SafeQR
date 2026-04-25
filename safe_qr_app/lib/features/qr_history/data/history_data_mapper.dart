import 'dart:convert';

import '../domain/entities/history_item.dart';
import 'history_table.dart';

typedef HistoryRow = Map<String, Object?>;

final class HistoryDataMapper {
  const HistoryDataMapper._();

  static HistoryItem fromRow(HistoryRow row) {
    final typeRaw = (row[HistoryTable.colType]! as String).toLowerCase();
    final type = typeRaw == 'scan' ? HistoryItemType.scan : HistoryItemType.generated;
    final reasonsJson = row[HistoryTable.colReasonsJson] as String? ?? '[]';
    final list = (jsonDecode(reasonsJson) as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final s = row[HistoryTable.colSafeToOpen];
    return HistoryItem(
      id: row[HistoryTable.colId]! as String,
      type: type,
      content: row[HistoryTable.colContent]! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row[HistoryTable.colCreatedAt]! as int),
        isUtc: true,
      ).toLocal(),
      verdict: row[HistoryTable.colVerdict] as String?,
      safeToOpen: s == null ? null : (s as int) == 1,
      reasons: list,
    );
  }

  static Map<String, Object?> toRow(HistoryItem item) {
    return {
      HistoryTable.colId: item.id,
      HistoryTable.colType: item.type == HistoryItemType.scan ? 'scan' : 'generated',
      HistoryTable.colContent: item.content,
      HistoryTable.colCreatedAt: item.createdAt.millisecondsSinceEpoch,
      HistoryTable.colVerdict: item.verdict,
      HistoryTable.colSafeToOpen: item.safeToOpen == null ? null : (item.safeToOpen! ? 1 : 0),
      HistoryTable.colReasonsJson: jsonEncode(item.reasons),
    };
  }
}
