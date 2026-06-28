import 'package:flutter/material.dart';

/// 공통 스낵바 유틸리티
/// 
/// 앱 전체에서 일관된 스타일의 스낵바를 표시합니다.
class AppSnackBar {
  // Private constructor to prevent instantiation
  AppSnackBar._();

  /// 성공 스낵바
  /// 
  /// 초록색 배경의 성공 메시지를 표시합니다.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF00C853),
      duration: duration,
      action: action,
    );
  }

  /// 에러 스낵바
  /// 
  /// 빨간색 배경의 에러 메시지를 표시합니다.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFCF6679),
      duration: duration,
      action: action,
    );
  }

  /// 경고 스낵바
  /// 
  /// 주황색 배경의 경고 메시지를 표시합니다.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFFF9800),
      duration: duration,
      action: action,
    );
  }

  /// 정보 스낵바
  /// 
  /// 파란색 배경의 정보 메시지를 표시합니다.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF2196F3),
      duration: duration,
      action: action,
    );
  }

  /// 커스텀 스낵바
  /// 
  /// 사용자 정의 색상과 아이콘으로 스낵바를 표시합니다.
  static void showCustom(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor ?? const Color(0xFF1E1E1E),
      textColor: textColor,
      duration: duration,
      action: action,
    );
  }

  /// 로딩 스낵바
  /// 
  /// 진행 중 상태를 표시하는 스낵바입니다.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message,
  ) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(minutes: 1), // 긴 시간 (수동으로 닫아야 함)
      ),
    );
  }

  /// 내부 헬퍼 메서드
  static void _show(
    BuildContext context, {
    required String message,
    IconData? icon,
    required Color backgroundColor,
    Color? textColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor ?? Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }

  /// 현재 표시 중인 스낵바 숨기기
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// 모든 스낵바 제거
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// Result 패턴과 통합된 스낵바 확장
extension ResultSnackBarExtension on BuildContext {
  /// Result의 Failure를 자동으로 에러 스낵바로 표시
  void showResultError(String errorMessage) {
    AppSnackBar.showError(this, errorMessage);
  }

  /// Result의 Success를 자동으로 성공 스낵바로 표시
  void showResultSuccess(String successMessage) {
    AppSnackBar.showSuccess(this, successMessage);
  }
}
