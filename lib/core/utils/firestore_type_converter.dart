import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/logger.dart';

/// Firestore 데이터 타입 변환 유틸리티
/// 
/// Timestamp, String(ISO 8601), int(milliseconds) 형태의 날짜를 처리
class FirestoreTypeConverter {
  FirestoreTypeConverter._();

  /// 날짜 필드를 milliseconds로 변환
  /// 
  /// 지원하는 타입:
  /// - Timestamp: Firestore 네이티브 타입
  /// - String: ISO 8601 형식 (예: "2025-12-19T00:54:11.329")
  /// - int: millisecondsSinceEpoch
  /// - null: null 반환
  static int? dateToMillis(dynamic field, {String fieldName = 'date'}) {
    if (field == null) return null;

    try {
      if (field is Timestamp) {
        return field.millisecondsSinceEpoch;
      } else if (field is String) {
        return DateTime.parse(field).millisecondsSinceEpoch;
      } else if (field is int) {
        return field;
      } else {
        AppLogger.w('Unexpected date type for $fieldName: ${field.runtimeType}');
        return null;
      }
    } catch (e) {
      AppLogger.e('Failed to convert $fieldName: $field', e);
      return null;
    }
  }

  /// 날짜 필드를 DateTime으로 변환
  static DateTime? dateToDateTime(dynamic field, {String fieldName = 'date'}) {
    final millis = dateToMillis(field, fieldName: fieldName);
    if (millis == null) return null;
    
    try {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (e) {
      AppLogger.e('Failed to create DateTime from $fieldName: $millis', e);
      return null;
    }
  }

  /// Timestamp를 ISO 8601 문자열로 변환
  static String? timestampToIso8601(dynamic field, {String fieldName = 'timestamp'}) {
    if (field == null) return null;

    try {
      if (field is Timestamp) {
        return field.toDate().toIso8601String();
      } else if (field is String) {
        // 이미 문자열이면 DateTime으로 파싱 후 다시 ISO 8601로 변환 (검증)
        return DateTime.parse(field).toIso8601String();
      } else if (field is int) {
        return DateTime.fromMillisecondsSinceEpoch(field).toIso8601String();
      } else {
        AppLogger.w('Unexpected timestamp type for $fieldName: ${field.runtimeType}');
        return null;
      }
    } catch (e) {
      AppLogger.e('Failed to convert $fieldName to ISO 8601: $field', e);
      return null;
    }
  }
}
