import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

/// 알림 서비스 Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// FCM 토큰 Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.fcmToken;
});



