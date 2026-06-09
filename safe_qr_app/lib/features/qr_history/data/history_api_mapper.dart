import '../domain/entities/history_item.dart';

/// Mapeamento [HistoryItem] ↔ JSON da API `/v1/history`.
final class HistoryApiMapper {
  const HistoryApiMapper._();

  static Map<String, dynamic> itemToApiJson(HistoryItem item) {
    return <String, dynamic>{
      'id': item.id,
      'type': item.type == HistoryItemType.scan ? 'scan' : 'generated',
      'content': item.content,
      'createdAtMs': item.createdAt.millisecondsSinceEpoch,
      'verdict': item.verdict,
      'safeToOpen': item.safeToOpen,
      'reasons': item.reasons,
    };
  }

  static HistoryItem itemFromApiJson(Map<String, dynamic> json) {
    final String typeRaw = (json['type'] as String? ?? '').toLowerCase();
    final HistoryItemType type =
        typeRaw == 'generated' ? HistoryItemType.generated : HistoryItemType.scan;
    final List<String> reasons = _parseStringList(json['reasons']);
    final Object? safeRaw = json['safeToOpen'] ?? json['safe_to_open'];
    bool? safeToOpen;
    if (safeRaw is bool) {
      safeToOpen = safeRaw;
    } else if (safeRaw is int) {
      safeToOpen = safeRaw == 1;
    }

    return HistoryItem(
      id: json['id'] as String,
      type: type,
      content: json['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMs'] as int? ?? json['created_at_ms'] as int? ?? 0,
        isUtc: true,
      ).toLocal(),
      verdict: json['verdict'] as String?,
      safeToOpen: safeToOpen,
      reasons: reasons,
    );
  }

  static List<HistoryItem> itemsFromListResponse(Map<String, dynamic> body) {
    final Object? raw = body['items'];
    if (raw is! List) {
      return const <HistoryItem>[];
    }
    return raw
        .map(_itemMapFromDynamic)
        .whereType<Map<String, dynamic>>()
        .map(itemFromApiJson)
        .toList(growable: false);
  }

  /// JSON decode devolve `List<dynamic>` / `Map` genérico — nunca `List<String>`.
  static List<String> _parseStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return List<String>.from(raw.map((dynamic e) => e.toString()));
  }

  static Map<String, dynamic>? _itemMapFromDynamic(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}
