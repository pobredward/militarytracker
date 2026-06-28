import 'package:intl/intl.dart';

class DateFormatter {
  // yyyy-MM-dd
  static String toDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  // yyyy-MM-dd HH:mm:ss
  static String toDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  // HH:mm
  static String toTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  // yyyy년 MM월 dd일
  static String toKoreanDate(DateTime dateTime) {
    return DateFormat('yyyy년 MM월 dd일').format(dateTime);
  }

  // MM월 dd일
  static String toShortKoreanDate(DateTime dateTime) {
    return DateFormat('MM월 dd일').format(dateTime);
  }

  // 상대 시간 (1분 전, 1시간 전 등)
  static String toRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

