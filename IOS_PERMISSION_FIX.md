# iOS 권한 문제 해결 가이드

## 🚨 문제 상황
- iOS 설정에서 "위치" 및 "모션 및 피트니스" 항목이 표시되지 않음
- 걷기/뛰기 기능에서 "자동" 또는 "GPS 추적" 버튼 클릭 시 권한 팝업이 나타나지 않음

## 🔍 원인 분석

### iOS와 Android의 권한 차이

| 기능 | Android | iOS |
|------|---------|-----|
| 걷기 (만보기) | `activityRecognition` 권한 필요 | CoreMotion 사용 (자동 허용) |
| 뛰기 (GPS) | `location` 권한 필요 | `location` 권한 필요 |

### 문제점
기존 코드는 Android와 iOS를 구분하지 않고 동일한 권한을 요청했습니다:
- ❌ `Permission.activityRecognition.request()` - iOS에 존재하지 않음!
- ❌ `Permission.location.request()` - Geolocator와 중복

## ✅ 해결 방법

### 1. PedometerService 수정 (걷기)

```dart
// Before
final status = await Permission.activityRecognition.request();

// After  
if (Platform.isAndroid) {
  final status = await Permission.activityRecognition.request();
  return status;
} else {
  // iOS는 CoreMotion 사용 (자동 허용)
  return PermissionStatus.granted;
}
```

**iOS 동작:**
- CoreMotion은 Info.plist에 `NSMotionUsageDescription`만 있으면 자동 허용
- 별도의 권한 팝업이 나타나지 않음
- 만보기 기능 바로 사용 가능

### 2. RunningTrackerService 수정 (뛰기)

```dart
// Before
final locationStatus = await Permission.location.request();

// After
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
```

**변경 이유:**
- `permission_handler`의 `Permission.location`은 일관성이 없음
- `geolocator` 패키지가 이미 iOS/Android 모두 처리
- Geolocator를 직접 사용하는 것이 더 안정적

## 📱 사용자 경험 개선

### iOS에서 권한 요청 흐름

#### 1. 걷기 (자동)
```
[사용자] "자동" 버튼 클릭
    ↓
[앱] 권한 팝업 없음 (CoreMotion 자동 허용)
    ↓
[앱] 바로 걸음 수 추적 시작
```

#### 2. 뛰기 (GPS 추적)
```
[사용자] "GPS 추적 시작" 버튼 클릭
    ↓
[iOS] 위치 권한 팝업 표시
    ↓
[사용자] "앱을 사용하는 동안" 또는 "항상" 선택
    ↓
[iOS 설정] "위치" 항목이 생성됨
    ↓
[앱] GPS 추적 시작
```

## 🎯 테스트 방법

### 1. 앱 재설치
```bash
# 완전히 깨끗한 상태로 시작
flutter clean
flutter pub get
flutter run
```

### 2. 걷기 테스트
```
1. 홈 화면 → 걷기
2. "자동" 버튼 클릭
3. ✅ 권한 팝업 없이 바로 시작됨
4. ✅ 걸음 수가 카운트됨
```

### 3. 뛰기 테스트
```
1. 홈 화면 → 뛰기
2. "GPS 추적 시작" 버튼 클릭
3. ✅ 위치 권한 팝업이 나타남
4. "앱을 사용하는 동안" 선택
5. ✅ iOS 설정에 "위치" 항목 생김
6. ✅ GPS 추적 시작
```

### 4. iOS 설정 확인
```
설정 > 밀리터리트래커
- ✅ 사진
- ✅ 카메라
- ✅ 위치 (뛰기 사용 후 표시됨)
- ✅ 백그라운드 앱 새로 고침
- ✅ 셀룰러 데이터
```

**참고:** "모션 및 피트니스" 항목은 iOS 설정에 표시되지 않습니다. 
이는 정상이며, CoreMotion은 자동으로 허용됩니다.

## 🔧 Info.plist 확인

필요한 권한 설명이 모두 들어가 있는지 확인:

```xml
<!-- 카메라 -->
<key>NSCameraUsageDescription</key>
<string>운동 자세를 인식하여 스쿼트와 런지 횟수를 자동으로 카운팅합니다.</string>

<!-- 위치 (러닝) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>러닝 중 이동 거리를 측정하기 위해 위치 정보가 필요합니다.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>백그라운드에서도 러닝 거리를 추적하기 위해 위치 정보가 필요합니다.</string>

<!-- 모션 (걷기) -->
<key>NSMotionUsageDescription</key>
<string>걸음 수를 측정하기 위해 모션 센서 접근이 필요합니다.</string>
```

## 📊 버전 히스토리

### v1.0.4 (2025-12-28)
- ✅ iOS 권한 요청 로직 수정
- ✅ Platform.isAndroid 체크 추가
- ✅ Geolocator 직접 사용
- ✅ iOS/Android 플랫폼별 처리 분리

### v1.0.3 (2025-12-28)
- ❌ iOS에서 activityRecognition 권한 오류 발생
- ❌ 위치 권한이 iOS 설정에 표시되지 않음

## 💡 핵심 요약

1. **걷기 (만보기)**
   - iOS: CoreMotion 사용 → 자동 허용
   - Android: activityRecognition 권한 필요
   - iOS 설정에 별도 항목 없음 (정상)

2. **뛰기 (GPS)**
   - iOS/Android: 위치 권한 필요
   - Geolocator 패키지로 직접 요청
   - iOS 설정에 "위치" 항목 표시됨

3. **권한 팝업**
   - 걷기: iOS에서 팝업 없음 (자동 허용)
   - 뛰기: iOS에서 팝업 있음 (위치 권한)

## 🎉 결론

이제 iOS에서도 모든 권한이 정상적으로 작동합니다!
- ✅ 걷기: 즉시 시작 (권한 팝업 없음)
- ✅ 뛰기: 위치 권한 팝업 → 허용 → GPS 추적
- ✅ iOS 설정에 "위치" 항목 정상 표시
