import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../core/config/logger.dart';

// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// 초기화
  Future<void> initialize() async {
    // 웹에서는 FCM 초기화를 건너뜀 (Service Worker 문제)
    if (kIsWeb) {
      logger.w('FCM is not fully supported on web, skipping initialization');
      return;
    }

    // 타임존 초기화
    tz.initializeTimeZones();
    
    // FCM 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 권한 요청
    await _requestPermission();

    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // FCM 토큰 가져오기
    _fcmToken = await _fcm.getToken();
    logger.i('FCM Token: $_fcmToken');

    // 토큰 갱신 리스너
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      logger.i('FCM Token refreshed: $token');
      // TODO: 서버에 토큰 업데이트
    });

    // 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드에서 알림 클릭 시
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 앱이 종료된 상태에서 알림으로 실행된 경우
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// 권한 요청
  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    logger.i('Notification permission: ${settings.authorizationStatus}');
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'military_tracker_channel',
      'Military Tracker Notifications',
      description: '운동 알림 및 업적 알림',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    logger.i('Foreground message: ${message.messageId}');
    
    // 로컬 알림으로 표시
    _showLocalNotification(
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// 알림 클릭 처리
  void _handleMessageOpenedApp(RemoteMessage message) {
    logger.i('Message opened: ${message.messageId}');
    // TODO: 알림 클릭 시 특정 화면으로 이동
  }

  /// 로컬 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    logger.i('Notification tapped: ${response.payload}');
    // TODO: 알림 클릭 시 특정 화면으로 이동
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'military_tracker_channel',
      'Military Tracker Notifications',
      channelDescription: '운동 알림 및 업적 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 예약 알림 설정 (일일 알림)
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // 웹에서는 예약 알림을 지원하지 않음
    if (kIsWeb) {
      logger.w('Scheduled notifications are not supported on web');
      return;
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // 이미 지난 시간이면 다음 날로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      0, // 일일 알림 ID
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'military_tracker_channel',
          'Military Tracker Notifications',
          channelDescription: '운동 알림 및 업적 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );

    logger.i('Daily notification scheduled at $hour:$minute');
  }

  /// 운동 시간 알림 설정
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    await scheduleDailyNotification(
      hour: hour,
      minute: minute,
      title: '운동 시간이에요! 💪',
      body: '오늘의 목표를 달성해보세요!',
    );
  }

  /// 알림 취소
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    logger.i('Subscribed to topic: $topic');
  }

  /// 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    logger.i('Unsubscribed from topic: $topic');
  }
}

