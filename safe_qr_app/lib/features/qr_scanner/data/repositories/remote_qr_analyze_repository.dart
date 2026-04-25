import '../../../../core/config/app_build_info.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/logging/app_debug_log.dart';
import '../../../../core/network/app_network.dart';
import '../../domain/entities/qr_security_verdict.dart';
import '../../domain/repositories/qr_analyze_repository.dart';
import '../mappers/qr_analysis_mappers.dart';
import '../models/qr_analyze_dto.dart';

/// Chama [POST /v1/qr/analyze] no [AppNetwork] (backend remoto).
final class RemoteQrAnalyzeRepository implements QrAnalyzeRepository {
  RemoteQrAnalyzeRepository(this._net);
  final AppNetwork _net;

  @override
  Future<QrAnalysisResult> analyze(
    String rawContent, {
    String? appVersion,
    String? platform,
  }) async {
    AppDebugLog.reader(
      'RemoteQrAnalyzeRepository.analyze rawLen=${rawContent.length} path=${AppEndpoints.qrAnalyze}',
    );
    final map = await _net.post(
      AppEndpoints.qrAnalyze,
      body: <String, dynamic>{
        'rawContent': rawContent,
        'client': <String, dynamic>{
          'appVersion': appVersion ?? AppBuildInfo.versionLabel,
          'platform': platform ?? 'android',
        },
      },
    );
    final dto = QrAnalyzeDto.fromJson(map);
    return QrAnalysisMappers.toDomain(dto);
  }
}
