import 'package:flutter_test/flutter_test.dart';
import 'package:safe_qr_app/features/qr_history/data/history_data_mapper.dart';
import 'package:safe_qr_app/features/qr_history/data/history_table.dart';
import 'package:safe_qr_app/features/qr_history/domain/entities/history_item.dart';

void main() {
  test('round-trip do mapa de linha (scan)', () {
    const id = '1';
    final m = <String, Object?>{
      HistoryTable.colId: id,
      HistoryTable.colType: 'scan',
      HistoryTable.colContent: 'https://a.com',
      HistoryTable.colCreatedAt: 1,
      HistoryTable.colVerdict: 'safe',
      HistoryTable.colSafeToOpen: 1,
      HistoryTable.colReasonsJson: '["a"]',
    };
    final item = HistoryDataMapper.fromRow(m);
    expect(item.type, HistoryItemType.scan);
    expect(item.safeToOpen, isTrue);
    final back = HistoryDataMapper.toRow(item);
    expect(back[HistoryTable.colId], id);
  });
}
