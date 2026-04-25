import 'package:equatable/equatable.dart';

enum QrSecurityVerdict { safe, suspicious, unsafe, unknown }

class QrParsedSummary extends Equatable {
  const QrParsedSummary({this.type, this.scheme, this.host});
  final String? type;
  final String? scheme;
  final String? host;
  @override
  List<Object?> get props => <Object?>[type, scheme, host];
}

class QrAnalysisResult extends Equatable {
  const QrAnalysisResult({
    required this.requestId,
    required this.verdict,
    required this.safeToOpen,
    required this.reasons,
    this.parsed,
  });

  final String requestId;
  final QrSecurityVerdict verdict;
  final bool safeToOpen;
  final List<String> reasons;
  final QrParsedSummary? parsed;

  @override
  List<Object?> get props => <Object?>[requestId, verdict, safeToOpen, reasons, parsed];
}
