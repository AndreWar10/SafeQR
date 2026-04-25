import 'dart:async';

import 'package:dio/dio.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/analyze_mode.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_endpoints.dart';
import '../../core/logging/app_debug_log.dart';
import '../../core/database/app_database_bootstrapper.dart';
import '../../core/network/app_network.dart';
import '../../core/theme/app_theme_mode_controller.dart';
import '../../features/qr_generator/domain/use_cases/validate_qr_payload.dart';
import '../../features/qr_generator/presentation/view_models/qr_generator_view_model.dart';
import '../../features/qr_history/data/repositories/history_repository_impl.dart';
import '../../features/qr_history/domain/repositories/history_repository.dart';
import '../../features/qr_history/domain/use_cases/add_history_item.dart';
import '../../features/qr_history/domain/use_cases/clear_history.dart';
import '../../features/qr_history/domain/use_cases/delete_history_item.dart';
import '../../features/qr_history/domain/use_cases/load_history_list.dart';
import '../../features/qr_history/presentation/view_models/qr_history_view_model.dart';
import '../../features/qr_scanner/data/local/qr_local_heuristic_engine.dart';
import '../../features/qr_scanner/data/repositories/local_heuristic_qr_analyze_repository.dart';
import '../../features/qr_scanner/data/repositories/remote_qr_analyze_repository.dart';
import '../../features/qr_scanner/domain/repositories/qr_analyze_repository.dart';
import '../../features/qr_scanner/domain/use_cases/analyze_qr_code.dart';
import '../../features/qr_scanner/presentation/view_models/qr_reader_view_model.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  required AppConfig appConfig,
  required SharedPreferences sharedPreferences,
}) async {
  if (sl.isRegistered<AppConfig>()) {
    await sl.reset(dispose: true);
  }

  sl
    ..registerSingleton<AppConfig>(appConfig)
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    ..registerSingleton<AppThemeModeController>(
      AppThemeModeController(
        prefs: sharedPreferences,
        persistenceKey: appConfig.themePersistenceKey,
      ),
    );

  final db = await const AppDatabaseBootstrapper().open();
  sl.registerSingleton<Database>(db);

  sl
    ..registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(sl()))
    ..registerLazySingleton<AddHistoryItem>(() => AddHistoryItem(sl()))
    ..registerLazySingleton<LoadHistoryList>(() => LoadHistoryList(sl()))
    ..registerLazySingleton<DeleteHistoryItem>(() => DeleteHistoryItem(sl()))
    ..registerLazySingleton<ClearHistory>(() => ClearHistory(sl()))
    ..registerLazySingleton<ValidateQrPayload>(() => const ValidateQrPayload());

  final dio = d.Dio(
    d.BaseOptions(
      baseUrl: appConfig.apiBaseUrl,
      connectTimeout: appConfig.connectTimeout,
      receiveTimeout: appConfig.receiveTimeout,
      headers: <String, Object?>{
        d.Headers.acceptHeader: d.Headers.jsonContentType,
        d.Headers.contentTypeHeader: d.Headers.jsonContentType,
      },
    ),
  );
  AppDebugLog.net(
    'Dio configurado baseUrl=${appConfig.apiBaseUrl} analyzeMode=${appConfig.analyzeMode}',
  );
  sl
    ..registerSingleton<d.Dio>(dio)
    ..registerLazySingleton<AppNetwork>(() => DioAppNetwork(dio: sl()))
    ..registerLazySingleton<QrAnalyzeRepository>(
      () {
        final AppConfig cfg = sl<AppConfig>();
        if (cfg.analyzeMode == AnalyzeMode.local) {
          return const LocalHeuristicQrAnalyzeRepository(QrLocalHeuristicEngine());
        }
        return RemoteQrAnalyzeRepository(sl());
      },
    )
    ..registerLazySingleton<AnalyzeQrCode>(() => AnalyzeQrCode(sl()))
    ..registerLazySingleton<QrReaderViewModel>(
      () => QrReaderViewModel(
        analyze: sl(),
        addToHistory: sl(),
      ),
    )
    ..registerLazySingleton<QrGeneratorViewModel>(
      () => QrGeneratorViewModel(
        addToHistory: sl(),
        validate: sl(),
      ),
    )
    ..registerLazySingleton<QrHistoryViewModel>(
      () => QrHistoryViewModel(
        load: sl(),
        deleteOne: sl(),
        clearAll: sl(),
      ),
    );

  if (kDebugMode && appConfig.analyzeMode == AnalyzeMode.remote) {
    unawaited(_debugProbeBackendHealth(appConfig));
  }
}

/// Em debug, confirma logo no arranque se a base URL alcança o back (evita “scan → loading → timeout” sem pista).
Future<void> _debugProbeBackendHealth(AppConfig cfg) async {
  try {
    await sl<AppNetwork>().get(AppEndpoints.health);
    AppDebugLog.net(
      'Bootstrap: GET ${cfg.apiBaseUrl}${AppEndpoints.health} OK (o back está acessível deste aparelho)',
    );
  } catch (e, st) {
    AppDebugLog.net(
      'Bootstrap: GET ${cfg.apiBaseUrl}${AppEndpoints.health} FALHOU. '
      'Em telefone físico não use 10.0.2.2 (só emulador); use o IP LAN do PC (ex. 192.168.x.x). '
      'Erro: $e',
      e,
      st,
    );
  }
}
