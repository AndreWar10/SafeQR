import '../../../../core/config/app_build_info.dart';
import '../../../../core/constants/app_endpoints.dart';
import '../../../../core/logging/app_debug_log.dart';
import '../../../../core/network/app_network.dart';
import '../../../../core/platform/app_platform_label.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../history_api_mapper.dart';

/// Histórico na nuvem — `GET/POST/DELETE /v1/history` (Bearer via [AppNetwork]).
final class RemoteHistoryRepository implements HistoryRepository {
  RemoteHistoryRepository(this._net);

  final AppNetwork _net;

  Map<String, dynamic> _clientBlock() {
    return <String, dynamic>{
      'appVersion': AppBuildInfo.versionLabel,
      'platform': AppPlatformLabel.current(),
    };
  }

  @override
  Future<void> add(HistoryItem item) async {
    AppDebugLog.history('POST ${AppEndpoints.history} id=${item.id} type=${item.type.name}');
    await _net.post(
      AppEndpoints.history,
      body: <String, dynamic>{
        'item': HistoryApiMapper.itemToApiJson(item),
        'client': _clientBlock(),
      },
    );
    AppDebugLog.history('POST ${AppEndpoints.history} OK id=${item.id}');
  }

  @override
  Future<List<HistoryItem>> list() async {
    const int limit = 100;
    const int offset = 0;
    AppDebugLog.history('GET ${AppEndpoints.history} limit=$limit offset=$offset');
    final Map<String, dynamic> body = await _net.get(
      AppEndpoints.history,
      queryParameters: <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final List<HistoryItem> items = HistoryApiMapper.itemsFromListResponse(body);
    AppDebugLog.history('GET ${AppEndpoints.history} OK count=${items.length}');
    return items;
  }

  @override
  Future<void> deleteById(String id) async {
    AppDebugLog.history('DELETE ${AppEndpoints.historyItem(id)}');
    await _net.delete(AppEndpoints.historyItem(id));
    AppDebugLog.history('DELETE ${AppEndpoints.historyItem(id)} OK');
  }

  @override
  Future<void> clear() async {
    AppDebugLog.history('DELETE ${AppEndpoints.history} (clear)');
    await _net.delete(AppEndpoints.history);
    AppDebugLog.history('DELETE ${AppEndpoints.history} OK (clear)');
  }
}
