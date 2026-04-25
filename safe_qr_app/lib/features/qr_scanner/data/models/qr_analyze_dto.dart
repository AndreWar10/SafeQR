final class QrAnalyzeDto {
  const QrAnalyzeDto({
    required this.requestId,
    required this.verdict,
    required this.safeToOpen,
    required this.reasons,
    this.parsed,
  });

  final String requestId;
  final String verdict;
  final bool safeToOpen;
  final List<String> reasons;
  final QrParsedDto? parsed;

  static QrAnalyzeDto fromJson(Map<String, dynamic> j) {
    return QrAnalyzeDto(
      requestId: (j['requestId'] ?? j['request_id'] ?? '').toString(),
      verdict: (j['verdict'] ?? 'unknown').toString(),
      safeToOpen: _readBool(j['safeToOpen'] ?? j['safe_to_open']),
      reasons: (j['reasons'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false),
      parsed: j['parsed'] is Map<String, dynamic> ? QrParsedDto.fromJson(j['parsed'] as Map<String, dynamic>) : null,
    );
  }
}

bool _readBool(Object? o) {
  if (o is bool) return o;
  if (o == null) return false;
  return o.toString().toLowerCase() == 'true';
}

final class QrParsedDto {
  const QrParsedDto({this.type, this.scheme, this.host});
  final String? type;
  final String? scheme;
  final String? host;

  static QrParsedDto fromJson(Map<String, dynamic> j) {
    return QrParsedDto(
      type: j['type'] as String?,
      scheme: j['scheme'] as String?,
      host: j['host'] as String?,
    );
  }
}
