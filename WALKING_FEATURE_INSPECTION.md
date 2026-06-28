# 걷기 기능 종합 점검 보고서 🚶‍♂️

## 개요

이 문서는 밀리터리트래커 앱의 **걷기(만보기) 기능**에 대한 전체 점검 결과와 백그라운드 지원 개선 사항을 설명합니다.

## 핵심 개선 사항 ✅

### 1. 백그라운드 실행 지원

앱이 닫혀있거나 백그라운드에 있을 때도 걸음 수가 **자동으로 계속 추적**됩니다!

#### iOS 설정 (`ios/Runner/Info.plist`)
```xml
<!-- 백그라운드 모드 -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>  ← 새로 추가
</array>

<!-- 백그라운드 태스크 식별자 -->
<key>UIBackgroundTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourcompany.militarytracker.pedometer</string>
</array>
```

### 2. 상태 지속성 (State Persistence)

앱을 종료하고 다시 열어도 걷기 추적 상태가 **자동으로 복원**됩니다.

#### 저장되는 데이터
- `pedometer_is_tracking`: 추적 중인지 여부
- `pedometer_initial_steps`: 세션 시작 시 걸음 수
- `pedometer_session_start_time`: 세션 시작 시간

#### 구현 (`lib/services/pedometer_service.dart`)
```dart
// SharedPreferences로 상태 저장
Future<void> _saveTrackingState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyIsTracking, _isTracking);
  await prefs.setInt(_keyInitialSteps, _initialSteps);
  if (_sessionStartTime != null) {
    await prefs.setInt(_keySessionStartTime, _sessionStartTime!.millisecondsSinceEpoch);
  }
}

// 앱 시작 시 상태 복원
Future<void> restoreTrackingState() async {
  final prefs = await SharedPreferences.getInstance();
  final wasTracking = prefs.getBool(_keyIsTracking) ?? false;
  
  if (wasTracking) {
    _initialSteps = prefs.getInt(_keyInitialSteps) ?? 0;
    // ... 추적 재개
  }
}
```

### 3. Provider 생명주기 최적화

화면을 나가도 추적이 **중단되지 않도록** Provider를 수정했습니다.

#### 변경 전 (문제)
```dart
// autoDispose로 인해 화면 나가면 서비스 종료됨
final stepCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final service = ref.watch(pedometerServiceProvider);
  return service.stepCountStream;
});
```

#### 변경 후 (해결)
```dart
// autoDispose 제거 - 앱 종료까지 유지
final stepCountStreamProvider = StreamProvider<int>((ref) {
  final service = ref.watch(pedometerServiceProvider);
  return service.stepCountStream;
});
```

### 4. 앱 생명주기 모니터링

백그라운드/포그라운드 전환을 감지하여 추적 상태를 관리합니다.

#### 구현 (`lib/main.dart`)
```dart
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 복귀
        debugPrint('App resumed - Pedometer continues tracking');
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 전환
        debugPrint('App paused - Pedometer continues tracking in background');
        break;
      // ...
    }
  }
}
```

## 걷기 기능 작동 원리 🔧

### iOS CMPedometer의 동작 방식

iOS는 **Core Motion 프레임워크의 CMPedometer**를 사용하여 걸음 수를 추적합니다:

1. **하드웨어 센서**: 가속도계, 자이로스코프 등을 활용
2. **백그라운드 지원**: iOS가 시스템 레벨에서 걸음 수 계속 카운트
3. **누적 카운트**: 디바이스 부팅 이후 총 걸음 수를 제공
4. **저전력**: 배터리 효율적인 방식으로 동작

### 우리 앱의 구현

```
[iOS CMPedometer] (시스템 레벨)
        ↓
[Pedometer Package] (Flutter 플러그인)
        ↓
[PedometerService] (우리 서비스)
        ↓
[Provider] (상태 관리)
        ↓
[WalkingTrackerScreen] (UI)
```

#### 세션 관리
```dart
// 시작: 현재 총 걸음 수 저장
_initialSteps = _currentSteps;  // 예: 10,000

// 추적 중: 세션 걸음 수 = 현재 - 초기
int get currentSteps => _currentSteps - _initialSteps;
// 예: 10,500 - 10,000 = 500걸음

// 저장 후: 상태 초기화
await _clearSavedState();
```

## 사용자 시나리오 📱

### 시나리오 1: 정상적인 추적

```
1. 사용자가 "걷기 자동" 버튼 클릭
   ↓
2. 권한 승인 (필요 시)
   ↓
3. 추적 시작 (현재 걸음 수 10,000으로 기록)
   ↓
4. 사용자가 걷기 시작
   ↓
5. 실시간으로 걸음 수 증가 (10,050 → 50걸음 표시)
   ↓
6. "저장하기" 버튼 클릭
   ↓
7. Firebase에 50걸음 저장
   ↓
8. 추적 상태 초기화
```

### 시나리오 2: 백그라운드 추적 (핵심!)

```
1. 사용자가 걷기 추적 시작 (10,000걸음에서 시작)
   ↓
2. SharedPreferences에 상태 저장:
   - is_tracking: true
   - initial_steps: 10,000
   - start_time: 2025-01-01 09:00:00
   ↓
3. 사용자가 앱을 홈 버튼으로 닫음
   ↓
4. iOS가 백그라운드에서 계속 걸음 수 카운트
   ↓ (30분 후, 3,000걸음 더 걸음)
5. 사용자가 앱 다시 열기
   ↓
6. PedometerService.restoreTrackingState() 호출
   ↓
7. 저장된 상태 복원:
   - 추적 중임을 인식
   - initial_steps = 10,000 복원
   - 현재 걸음 수 = 13,000
   ↓
8. UI에 3,000걸음 표시! ✅
   ↓
9. 저장하면 3,000걸음이 Firebase에 저장됨
```

### 시나리오 3: 앱 완전 종료 후 재시작

```
1. 추적 중 상태에서 앱 스와이프로 완전 종료
   ↓
2. SharedPreferences에 상태는 여전히 저장됨
   ↓
3. iOS는 계속 걸음 수 카운트 (시스템 레벨)
   ↓
4. 사용자가 앱 재실행
   ↓
5. main() → PedometerService 초기화
   ↓
6. restoreTrackingState() 자동 호출
   ↓
7. 추적 재개 및 누적 걸음 수 계산 ✅
```

## 권한 관리 🔐

### 필요한 권한

#### iOS
- **NSMotionUsageDescription**: 모션 센서 접근
  - 설명: "걸음 수를 측정하기 위해 모션 센서 접근이 필요합니다."
  - 백그라운드에서도 자동으로 작동 (추가 권한 불필요)

### 권한 흐름

```dart
// 1. 권한 요청
Future<PermissionStatus> requestPermission() async {
  final status = await Permission.activityRecognition.request();
  return status;
}

// 2. 권한 거부 시 설정으로 이동
if (permissionStatus.isPermanentlyDenied) {
  await openAppSettings();
}
```

## 데이터 흐름 📊

### 추적 시작부터 저장까지

```
[사용자 클릭] → [권한 확인] → [추적 시작]
                                    ↓
                          [상태 저장 (SharedPreferences)]
                                    ↓
                          [CMPedometer 구독]
                                    ↓
                          [실시간 걸음 수 업데이트]
                                    ↓
                          [UI에 표시]
                                    ↓
                          [사용자 저장 클릭]
                                    ↓
                          [Firebase 저장]
                                    ↓
                          [상태 초기화]
```

### 백그라운드에서의 데이터 흐름

```
[앱 백그라운드] → [CMPedometer 계속 카운트]
                           ↓
                  [SharedPreferences에 상태 유지]
                           ↓
                  [앱 포그라운드 복귀]
                           ↓
                  [상태 복원]
                           ↓
                  [누적 걸음 수 계산]
                           ↓
                  [UI 업데이트] ✅
```

## 테스트 가이드 🧪

### 1. 기본 추적 테스트

```bash
# TestFlight 앱에서:
1. 운동 탭 → 걷기 "자동" 버튼 클릭
2. 권한 허용 (처음만)
3. 걸음 수가 0에서 시작하는지 확인
4. 실제로 걸어보기 (10걸음)
5. 걸음 수가 증가하는지 확인
6. "저장하기" 클릭
7. Firebase에 저장되는지 확인
```

### 2. 백그라운드 테스트 (핵심!)

```bash
# 방법 1: 홈 버튼으로 앱 최소화
1. 걷기 추적 시작
2. 초기 걸음 수 기록 (예: 50)
3. 홈 버튼 눌러 앱 최소화
4. 5분간 걷기 (약 500걸음)
5. 앱 다시 열기
6. 걸음 수가 약 550으로 증가했는지 확인 ✅

# 방법 2: 앱 완전 종료
1. 걷기 추적 시작
2. 초기 걸음 수 기록 (예: 100)
3. 앱 스와이프로 완전 종료
4. 10분간 걷기 (약 1,000걸음)
5. 앱 다시 시작
6. 자동으로 추적 재개되는지 확인
7. 걸음 수가 약 1,100으로 표시되는지 확인 ✅

# 방법 3: 다른 앱 사용 중
1. 걷기 추적 시작
2. Safari, 카메라 등 다른 앱 사용
3. 10분간 폰을 들고 다니기
4. 밀리터리트래커 앱으로 돌아오기
5. 걸음 수가 계속 증가했는지 확인 ✅
```

### 3. 권한 거부 테스트

```bash
1. 설정 → 밀리터리트래커 → 모션 & 피트니스 권한 끄기
2. 앱에서 걷기 자동 클릭
3. 권한 거부 대화상자 표시 확인
4. "설정으로 이동" 클릭
5. iOS 설정 앱 열림 확인
6. 권한 켜기
7. 앱으로 돌아와 다시 시도
8. 정상 작동 확인 ✅
```

### 4. 상태 복원 테스트

```bash
# 시뮬레이터/디버그 모드
1. 추적 시작
2. Xcode에서 앱 중지 (Stop 버튼)
3. 터미널에서 SharedPreferences 확인:
   xcrun simctl get_app_container booted com.yourcompany.militarytracker data
   cat Library/Preferences/*.plist
4. is_tracking=true, initial_steps 값 확인
5. 앱 다시 실행
6. 로그에서 "Restored tracking state" 확인 ✅
```

### 5. 배터리 효율 테스트

```bash
1. 충전 100% 상태
2. 걷기 추적 시작
3. 1시간 동안 일상 활동
4. 배터리 사용량 확인:
   설정 → 배터리 → 앱별 사용량
5. 밀리터리트래커가 과도한 배터리 사용하지 않는지 확인
   (예상: 1시간에 1-2% 이하)
```

## 알려진 제한사항 ⚠️

### iOS CMPedometer의 특성

1. **정확도**: 
   - 운동 강도와 패턴에 따라 ±5% 오차 가능
   - 평지 걷기가 가장 정확
   - 계단이나 러닝은 약간 부정확할 수 있음

2. **디바이스 요구사항**:
   - iPhone 5s 이상 (M7 코프로세서 필요)
   - iPad는 셀룰러 모델만 지원

3. **백그라운드 제한**:
   - iOS가 배터리 절약을 위해 일부 센서를 제한할 수 있음
   - 저전력 모드에서는 정확도 감소 가능

4. **권한**:
   - 한 번 거부하면 앱에서 재요청 불가
   - 사용자가 직접 설정 앱에서 변경해야 함

### 우리 앱의 제한

1. **세션 기반**: 
   - 하루 종일 누적 추적이 아닌 세션별 추적
   - 저장 전까지는 임시 데이터

2. **수동 저장**:
   - 자동 저장 없음 (사용자가 직접 저장 버튼 클릭)
   - 앱 크래시 시 저장 안 된 데이터 손실

3. **동시 추적 불가**:
   - 여러 세션을 동시에 추적할 수 없음
   - 한 번에 하나의 걷기 세션만 가능

## 개선 제안 💡

### 단기 개선 (즉시 가능)

1. **자동 저장 기능**
   ```dart
   // 1시간마다 자동 저장
   Timer.periodic(Duration(hours: 1), (timer) async {
     if (_isTracking && currentSteps > 0) {
       await autoSave();
     }
   });
   ```

2. **알림 추가**
   ```dart
   // 목표 달성 시 알림
   if (currentSteps >= AppConstants.walkGoal) {
     await NotificationService().showNotification(
       title: '목표 달성! 🎉',
       body: '오늘 ${currentSteps}걸음을 달성했습니다!',
     );
   }
   ```

3. **위젯 지원**
   - iOS 홈 화면 위젯으로 현재 걸음 수 표시
   - 앱 열지 않고도 진행 상황 확인

### 중기 개선 (2-4주)

1. **하루 종일 추적**
   - 자정에 자동으로 일일 걸음 수 저장
   - 매일 누적 기록 자동 관리

2. **통계 대시보드**
   - 주간/월간 평균 걸음 수
   - 그래프로 시각화
   - 목표 대비 달성률

3. **Apple Health 연동**
   ```dart
   // HealthKit과 동기화
   await HealthKit.write(
     type: HealthDataType.STEPS,
     value: currentSteps,
     dateTime: DateTime.now(),
   );
   ```

### 장기 개선 (1-3개월)

1. **AI 기반 패턴 분석**
   - 사용자의 걷기 패턴 학습
   - 최적의 운동 시간 추천
   - 개인화된 목표 제안

2. **소셜 기능**
   - 친구와 걸음 수 경쟁
   - 리더보드
   - 챌린지 시스템

3. **게임화 요소**
   - 배지 시스템
   - 레벨 업
   - 보상 아이템

## 성능 최적화 ⚡

### 메모리 관리

```dart
// StreamController는 broadcast로 생성하여 메모리 효율 개선
final _stepCountController = StreamController<int>.broadcast();

// dispose 시 반드시 정리
void dispose() {
  stopTracking();
  _stepCountController.close();
}
```

### 배터리 최적화

```dart
// 걸음 수 업데이트를 1초에 한 번으로 제한
void _onStepCount(StepCount event) {
  final now = DateTime.now();
  if (_lastUpdateTime != null && 
      now.difference(_lastUpdateTime!) < Duration(seconds: 1)) {
    return; // 너무 빈번한 업데이트 무시
  }
  
  _lastUpdateTime = now;
  _currentSteps = event.steps;
  _stepCountController.add(currentSteps);
}
```

## 디버깅 팁 🐛

### 로그 확인

```dart
// PedometerService의 모든 주요 이벤트 로깅
logger.i('Pedometer tracking started');
logger.d('Steps: $sessionSteps (Total: $_currentSteps)');
logger.e('Pedometer error: $error');
```

### Xcode 콘솔에서 확인할 로그

```
✅ 정상 작동:
[INFO] Pedometer tracking started
[DEBUG] Steps: 0 (Total: 10000)
[DEBUG] Steps: 1 (Total: 10001)
...
[INFO] Tracking state saved

❌ 권한 문제:
[ERROR] Activity recognition permission denied

❌ 센서 문제:
[ERROR] Pedometer error: CMErrorMotionActivityNotAvailable
```

### SharedPreferences 확인

```bash
# iOS 시뮬레이터
cd ~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Library/Preferences

# 실제 기기 (Xcode Devices)
# Window > Devices and Simulators > Download Container
```

## FAQ ❓

### Q1: 앱을 닫으면 걸음 수가 리셋되나요?
**A**: 아니요! SharedPreferences에 상태가 저장되어 있어서 앱을 다시 열면 자동으로 복원됩니다.

### Q2: 백그라운드에서도 정확하게 측정되나요?
**A**: 네, iOS의 CMPedometer가 시스템 레벨에서 계속 측정하므로 매우 정확합니다.

### Q3: 배터리 소모가 심한가요?
**A**: 아니요, iOS가 하드웨어 센서를 효율적으로 관리하여 배터리 영향이 거의 없습니다.

### Q4: 다른 만보기 앱과 동시에 사용할 수 있나요?
**A**: 네, 모든 앱이 같은 CMPedometer를 사용하므로 간섭 없이 함께 사용할 수 있습니다.

### Q5: 저장하지 않고 앱이 크래시되면?
**A**: 저장되지 않은 걸음 수는 손실됩니다. 향후 자동 저장 기능으로 개선 예정입니다.

### Q6: iPhone 외에 iPad에서도 작동하나요?
**A**: 셀룰러 모델의 iPad만 지원됩니다 (모션 센서 필요).

### Q7: Apple Watch와 동기화되나요?
**A**: 현재는 iPhone의 센서만 사용합니다. Apple Watch 연동은 향후 개선 사항입니다.

## 관련 파일 📁

### 핵심 파일
- `lib/services/pedometer_service.dart` - 만보기 서비스 (백그라운드 지원)
- `lib/providers/tracking_provider.dart` - 상태 관리 Provider
- `lib/features/workout/presentation/walking_tracker_screen.dart` - 걷기 추적 UI
- `ios/Runner/Info.plist` - iOS 권한 및 백그라운드 설정

### 설정 파일
- `pubspec.yaml` - 의존성 (pedometer: ^4.0.2)
- `lib/main.dart` - 앱 생명주기 관리

### 문서
- `PERMISSION_FIX_GUIDE.md` - 권한 설정 가이드
- `WORKOUT_TRACKING_GUIDE.md` - 운동 추적 전체 가이드
- `IOS_DEPLOYMENT_GUIDE.md` - iOS 배포 가이드

## 결론 🎯

### 개선 전 vs 개선 후

| 항목 | 개선 전 ❌ | 개선 후 ✅ |
|------|-----------|-----------|
| 백그라운드 추적 | 앱 최소화 시 중단 | 계속 추적 |
| 상태 저장 | 앱 종료 시 손실 | 자동 저장/복원 |
| Provider 생명주기 | 화면 나가면 종료 | 앱 종료까지 유지 |
| 권한 관리 | 에러 메시지만 표시 | 설정으로 이동 가능 |
| 앱 생명주기 | 모니터링 없음 | 상태 전환 감지 |

### 핵심 성과

✅ **완전한 백그라운드 지원**: 앱을 닫아도 걸음 수 계속 측정  
✅ **상태 지속성**: 앱 재시작 시 자동 복원  
✅ **사용자 경험 개선**: 권한 설정 원클릭 이동  
✅ **배터리 효율**: iOS 시스템 최적화 활용  
✅ **안정성 향상**: 에러 처리 및 로깅 개선  

### 다음 단계

1. **TestFlight 배포** 및 실제 사용자 테스트
2. **피드백 수집** 및 버그 수정
3. **자동 저장 기능** 구현
4. **Apple Health 연동** 검토
5. **통계 대시보드** 개발

---

**작성일**: 2025-01-27  
**버전**: 1.0.0  
**작성자**: Military Tracker Team  
**상태**: ✅ 백그라운드 지원 완료
