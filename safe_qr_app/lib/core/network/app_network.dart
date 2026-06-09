import 'package:dio/dio.dart' as d;

import '../logging/app_debug_log.dart';
import 'app_network_exception.dart';

/// Abstração sobre o cliente HTTP (Dio) para trocar implementação e testar facilmente.
abstract class AppNetwork {
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  });

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  });

  Future<void> delete(
    String path, {
    Map<String, String>? headers,
  });
}

class DioAppNetwork implements AppNetwork {
  DioAppNetwork({required d.Dio dio}) : _dio = dio;
  final d.Dio _dio;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) {
    return _withGuard(() async {
      final r = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: d.Options(headers: _headersWithoutBody(headers)),
      );
      return _mapResponse(r);
    });
  }

  @override
  Future<void> delete(
    String path, {
    Map<String, String>? headers,
  }) {
    return _withGuardVoid(() async {
      await _dio.delete<void>(
        path,
        options: d.Options(headers: _headersWithoutBody(headers)),
      );
    });
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) {
    return _withGuard(() async {
      final Uri url = Uri.parse(_dio.options.baseUrl).resolve(path);
      AppDebugLog.readerVerbose('POST $url (body keys: ${body.keys.join(',')})');
      final r = await _dio.post<dynamic>(path, data: body, options: d.Options(headers: headers));
      AppDebugLog.readerVerbose('POST $url → HTTP ${r.statusCode}');
      return _mapResponse(r);
    });
  }

  /// GET/DELETE sem corpo — não enviar `Content-Type: application/json` (Fastify rejeita).
  static Map<String, dynamic> _headersWithoutBody(Map<String, String>? extra) {
    return <String, dynamic>{
      d.Headers.contentTypeHeader: null,
      if (extra != null) ...extra,
    };
  }

  Map<String, dynamic> _mapResponse(d.Response<dynamic> r) {
    final d = r.data;
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return d.map((k, v) => MapEntry(k.toString(), v));
    throw const AppSerializationException('O JSON não é um objecto no topo');
  }

  Future<void> _withGuardVoid(Future<void> Function() run) async {
    try {
      await run();
    } on d.DioException catch (e, st) {
      _rethrowDio(e, st);
    } on AppNetworkException {
      rethrow;
    } catch (e, st) {
      AppDebugLog.net('Pedido sem corpo falhou: $e', e, st);
      throw AppSerializationException(e.toString());
    }
  }

  Future<Map<String, dynamic>> _withGuard(
    Future<Map<String, dynamic>> Function() run,
  ) async {
    try {
      return await run();
    } on d.DioException catch (e, st) {
      _rethrowDio(e, st);
    } on AppNetworkException {
      rethrow;
    } catch (e, st) {
      AppDebugLog.net('Resposta inesperada: $e', e, st);
      throw AppSerializationException(e.toString());
    }
  }

  static String _messageFromDioResponse(d.DioException e) {
    final Object? data = e.response?.data;
    if (data is Map) {
      final Object? message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final Object? error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return e.message ?? 'Falha de rede';
  }

  Never _rethrowDio(d.DioException e, StackTrace st) {
    final Uri uri = e.requestOptions.uri;
    AppDebugLog.net(
      'Dio falhou type=${e.type} uri=$uri status=${e.response?.statusCode} msg=${e.message}',
      e,
      st,
    );
    if (e.type == d.DioExceptionType.connectionTimeout || e.type == d.DioExceptionType.sendTimeout) {
      throw const AppHttpException('Timeout ao contactar o servidor', statusCode: 408);
    }
    if (e.type == d.DioExceptionType.connectionError) {
      throw AppHttpException(
        'Não foi possível ligar ao servidor ($uri). '
        'Em Android físico use o IP da máquina na Wi‑Fi; no emulador use 10.0.2.2; '
        'HTTP exige usesCleartextTraffic (já no manifesto de debug).',
        statusCode: 0,
      );
    }
    final code = e.response?.statusCode;
    throw AppHttpException(_messageFromDioResponse(e), statusCode: code);
  }
}
