import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logs para `adb logcat` / consola (filtre por `SafeQR`).
///
/// Em **release** continua a registar erros de rede/leitor (útil no campo);
/// mensagens verbosas só em modo não-release.
abstract final class AppDebugLog {
  static const String _net = 'SafeQR.Net';
  static const String _reader = 'SafeQR.Reader';
  static const String _identity = 'SafeQR.Identity';
  static const String _history = 'SafeQR.History';

  static void net(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: _net, error: error, stackTrace: stackTrace);
  }

  static void reader(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: _reader, error: error, stackTrace: stackTrace);
  }

  static void readerVerbose(String message) {
    if (kReleaseMode) {
      return;
    }
    developer.log(message, name: _reader);
  }

  static void identity(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: _identity, error: error, stackTrace: stackTrace);
  }

  static void identityVerbose(String message) {
    if (kReleaseMode) {
      return;
    }
    developer.log(message, name: _identity);
  }

  static void history(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: _history, error: error, stackTrace: stackTrace);
  }
}
