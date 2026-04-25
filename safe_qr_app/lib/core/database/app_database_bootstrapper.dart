import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database_names.dart';

/// Abre a base de dados e aplica a migração inicial.
final class AppDatabaseBootstrapper {
  const AppDatabaseBootstrapper();

  static const String _tableHistory = 'history';

  Future<Database> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppDatabaseNames.fileName);
    return openDatabase(
      path,
      version: AppDatabaseNames.schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $_tableHistory(
          id TEXT NOT NULL PRIMARY KEY,
          type TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at_ms INTEGER NOT NULL,
          verdict TEXT,
          safe_to_open INTEGER,
          reasons_json TEXT
        );
        ''');
        await db.execute('CREATE INDEX idx_history_time ON $_tableHistory(created_at_ms);');
      },
    );
  }
}
