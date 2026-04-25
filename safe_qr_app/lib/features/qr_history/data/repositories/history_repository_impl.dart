import 'package:sqflite/sqflite.dart';

import '../history_data_mapper.dart';
import '../history_table.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';

final class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._db);
  final Database _db;

  @override
  Future<void> add(HistoryItem item) async {
    await _db.insert(
      HistoryTable.name,
      HistoryDataMapper.toRow(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    await _db.delete(HistoryTable.name);
  }

  @override
  Future<void> deleteById(String id) async {
    await _db.delete(
      HistoryTable.name,
      where: '${HistoryTable.colId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<List<HistoryItem>> list() async {
    final rows = await _db.query(
      HistoryTable.name,
      orderBy: '${HistoryTable.colCreatedAt} DESC',
    );
    return rows.map(HistoryDataMapper.fromRow).toList(growable: false);
  }
}
