/// Nomes de coluna/tabela para evitar “magic strings” espalhadas.
abstract final class HistoryTable {
  static const String name = 'history';
  static const String colId = 'id';
  static const String colType = 'type';
  static const String colContent = 'content';
  static const String colCreatedAt = 'created_at_ms';
  static const String colVerdict = 'verdict';
  static const String colSafeToOpen = 'safe_to_open';
  static const String colReasonsJson = 'reasons_json';
}
