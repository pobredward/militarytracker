# 📱 푸시 알림 구현 가이드

## 현재 상태
현재 알림 설정 화면은 **로컬 설정만 저장**하며, 실제 푸시 알림과는 연동되어 있지 않습니다.

## 🎯 푸시 알림 구현 단계

### 1단계: Firebase Cloud Messaging (FCM) 설정

#### 1.1 Android 설정

1. **Firebase Console에서 Android 앱 추가**
   - Firebase Console → 프로젝트 설정 → 앱 추가
   - Android 패키지 이름 입력: `com.example.militarytracker`
   - `google-services.json` 다운로드
   - `android/app/` 폴더에 복사

2. **build.gradle 수정**

`android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

`android/app/build.gradle`:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id 'com.google.gms.google-services'  // 추가
}

android {
    defaultConfig {
        // ...
        minSdkVersion 21  // FCM 최소 요구사항
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

3. **AndroidManifest.xml 수정**

`android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- Android 13+ -->
    
    <application>
        <!-- 기존 내용 -->
        
        <!-- FCM 서비스 -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>
        
        <!-- 기본 알림 채널 -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="military_tracker_channel"/>
    </application>
</manifest>
```

#### 1.2 iOS 설정

1. **Apple Developer Console 설정**
   - Certificates, Identifiers & Profiles
   - App ID 생성 및 Push Notifications 활성화
   - APNs 인증 키 생성 (.p8 파일)

2. **Firebase Console에 APNs 키 업로드**
   - Firebase Console → 프로젝트 설정 → Cloud Messaging
   - APNs 인증 키 업로드

3. **Xcode 설정**
   - Signing & Capabilities → Push Notifications 추가
   - Background Modes → Remote notifications 체크

4. **Info.plist 수정**

`ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 2단계: Flutter 패키지 설치

`pubspec.yaml`:
```yaml
dependencies:
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.0
```

```bash
flutter pub get
```

### 3단계: 푸시 알림 서비스 구현

#### 3.1 알림 서비스 생성

`lib/services/notification_service.dart`:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
```

### 4단계: main.dart에서 초기화

`lib/main.dart`:
```dart
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 알림 서비스 초기화
  await NotificationService().initialize();
  
  // Local Storage 초기화
  await LocalStorage.init();
  
  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);
  
  runApp(
    const ProviderScope(
      child: MilitaryTrackerApp(),
    ),
  );
}
```

### 5단계: 알림 설정 화면 연동

`lib/features/profile/presentation/notification_settings_screen.dart` 수정:

```dart
import '../../../services/notification_service.dart';

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final _notificationService = NotificationService();
  
  // ... 기존 코드 ...

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 설정 저장
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setBool('workout_reminder', _workoutReminder);
    // ... 기타 설정 저장 ...
    
    // 알림 취소
    await _notificationService.cancelAllNotifications();
    
    // 활성화된 알림 재설정
    if (_dailyReminder) {
      await _notificationService.scheduleDailyNotification(
        hour: _dailyReminderTime.hour,
        minute: _dailyReminderTime.minute,
        title: '오늘의 운동 목표',
        body: '목표를 확인하고 운동을 시작해보세요!',
      );
    }
    
    if (_workoutReminder) {
      await _notificationService.scheduleWorkoutReminder(
        hour: _workoutReminderTime.hour,
        minute: _workoutReminderTime.minute,
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 설정이 저장되었습니다'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
    }
  }
}
```

### 6단계: 서버 측 구현 (선택사항)

업적 달성, 커뮤니티 댓글 등의 알림을 위해서는 서버에서 FCM API를 호출해야 합니다.

#### Firebase Admin SDK 사용 (Node.js 예시)

```javascript
const admin = require('firebase-admin');

// 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 특정 사용자에게 알림 전송
async function sendNotificationToUser(fcmToken, title, body, data) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.log('Error sending message:', error);
  }
}

// 토픽으로 알림 전송
async function sendNotificationToTopic(topic, title, body) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    topic: topic,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.log('Error sending message:', error);
  }
}
```

### 7단계: 테스트

#### 7.1 로컬 알림 테스트
```dart
// 테스트 버튼 추가
ElevatedButton(
  onPressed: () async {
    await NotificationService().scheduleDailyNotification(
      hour: DateTime.now().hour,
      minute: DateTime.now().minute + 1,
      title: '테스트 알림',
      body: '알림이 정상적으로 작동합니다!',
    );
  },
  child: Text('알림 테스트'),
)
```

#### 7.2 Firebase Console에서 테스트
1. Firebase Console → Cloud Messaging
2. "Send your first message" 클릭
3. 알림 제목, 내용 입력
4. 테스트 메시지 전송

## 📊 알림 종류별 구현

### 1. 일일 알림
- 매일 설정한 시간에 운동 목표 알림
- `scheduleDailyNotification` 사용

### 2. 운동 시간 알림
- 운동하기 좋은 시간에 알림
- `scheduleWorkoutReminder` 사용

### 3. 업적 알림
- 업적 달성 시 즉시 알림
- `_showLocalNotification` 사용

### 4. 커뮤니티 알림
- 댓글 작성 시 서버에서 FCM 전송
- 서버 측 구현 필요

### 5. 주간 리포트
- 매주 월요일 통계 알림
- 서버에서 스케줄링

## 🔒 보안 고려사항

1. **FCM 토큰 저장**
   - Firestore에 사용자별로 토큰 저장
   - 로그아웃 시 토큰 삭제

2. **권한 관리**
   - 사용자가 권한을 거부한 경우 처리
   - 설정 화면에서 권한 재요청 안내

3. **데이터 페이로드**
   - 민감한 정보는 페이로드에 포함하지 않음
   - 필요한 경우 암호화

## 📱 플랫폼별 제한사항

### Android
- Android 13+ : 알림 권한 명시적 요청 필요
- Doze 모드: 정확한 시간 알림 제한
- 배터리 최적화: 백그라운드 제한

### iOS
- APNs 인증서 필요
- 백그라운드 제한 엄격
- 알림 권한 한 번만 요청 가능

## 🚀 다음 단계

1. ✅ 기본 FCM 설정
2. ✅ 로컬 알림 구현
3. ✅ 예약 알림 구현
4. ⬜ 서버 측 FCM 전송
5. ⬜ 알림 분석 및 최적화
6. ⬜ Rich Notification (이미지, 액션 버튼)

## 📚 참고 자료

- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications 패키지](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

