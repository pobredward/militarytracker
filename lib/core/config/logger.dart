import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전역 로거
/// 
/// Production 환경에서는 WARNING 레벨 이상만 로깅
/// Development 환경에서는 모든 레벨 로깅
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: kDebugMode ? Level.debug : Level.warning,
  filter: ProductionFilter(),
);

/// AppLogger 래퍼 클래스
/// 
/// print 문 대신 사용하여 일관된 로깅 제공
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Debug 레벨 로그 (개발 환경에서만)
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Info 레벨 로그
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 레벨 로그
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 레벨 로그
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 레벨 로그 (치명적 오류)
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}
