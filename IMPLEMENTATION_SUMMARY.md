# 운동 추적 기능 구현 요약

## ✅ 구현 완료 사항

### 1. 패키지 추가 (pubspec.yaml)
```yaml
# 카메라 & ML Kit
camera: ^0.11.0+2
google_mlkit_pose_detection: ^0.13.0

# 센서 & 위치
pedometer: ^4.0.2
geolocator: ^13.0.2
permission_handler: ^11.3.1
```

### 2. 서비스 레이어 구현

#### PoseDetectionService (`lib/services/pose_detection_service.dart`)
- 카메라 이미지 스트림 처리
- ML Kit을 통한 스켈레톤 랜드마크 추출
- 스쿼트/런지 자세 분석 알고리즘
- 실시간 카운팅 스트림 제공

**핵심 로직:**
- 무릎 각도 계산 (3점 좌표 기반)
- 스쿼트: 무릎 각도 < 100도 → 앉은 상태 판정
- 런지: 한쪽 무릎 < 110도, 다른 쪽 > 160도 → 런지 자세 판정

#### PedometerService (`lib/services/pedometer_service.dart`)
- 디바이스 만보기 센서 스트림 구독
- 세션별 걸음 수 관리 (초기값 저장 후 증분 계산)
- 백그라운드 추적 지원

#### RunningTrackerService (`lib/services/running_tracker_service.dart`)
- GPS 위치 스트림 구독
- Haversine 공식으로 두 지점 간 거리 계산
- 실시간 속도, 평균 속도, 평균 페이스 계산
- 일시정지/재개 기능
- 비정상적인 GPS 오류 필터링 (1초에 100m 이상 이동 무시)

### 3. Provider 레이어 (`lib/providers/tracking_provider.dart`)
```dart
// 서비스 Provider
- poseDetectionServiceProvider
- pedometerServiceProvider
- runningTrackerServiceProvider

// 스트림 Provider
- poseCountStreamProvider (스쿼트/런지 카운트)
- stepCountStreamProvider (걸음 수)
- runningDistanceStreamProvider (러닝 거리)
- runningSpeedStreamProvider (러닝 속도)

// 상태 Provider
- isTrackingPedometerProvider
- isTrackingRunningProvider
- isPoseDetectionActiveProvider
- currentExerciseTypeProvider
```

### 4. UI 화면 구현

#### CameraWorkoutScreen (`lib/features/workout/presentation/camera_workout_screen.dart`)
- 전면 카메라 프리뷰
- 실시간 카운트 오버레이
- 운동 가이드 텍스트
- 저장 기능

#### WalkingTrackerScreen (`lib/features/workout/presentation/walking_tracker_screen.dart`)
- 실시간 걸음 수 표시
- 목표 대비 진행률 바
- 저장 버튼

#### RunningTrackerScreen (`lib/features/workout/presentation/running_tracker_screen.dart`)
- 실시간 거리/속도 표시
- 경과 시간 타이머
- 일시정지/재개 버튼
- 저장 확인 다이얼로그
- 목표 대비 진행률

#### WorkoutScreen 업데이트
- 각 운동 카드에 "자동" 또는 "GPS 추적" 버튼 추가
- 기존 수동 입력 기능 유지
- 새 화면으로 네비게이션

### 5. 데이터 모델 확장 (`lib/models/workout_model.dart`)
```dart
enum TrackingMode {
  manual,    // 수동 입력
  automatic, // 자동 인식
}

// WorkoutModel에 추가된 필드
TrackingMode squatMode;
TrackingMode lungeMode;
TrackingMode walkMode;
TrackingMode runMode;
```

### 6. 권한 설정

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<key>NSLocationWhenInUseUsageDescription</key>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<key>NSMotionUsageDescription</key>
<key>UIBackgroundModes</key>
```

## 🎯 사용자 플로우

### 스쿼트 자동 카운팅
```
운동 화면 
  → 스쿼트 카드의 "자동" 버튼 클릭
  → CameraWorkoutScreen 열림
  → 카메라 권한 요청
  → 전면 카메라 활성화
  → ML Kit 자세 인식 시작
  → 실시간 카운팅
  → 저장 버튼 클릭
  → Firestore에 저장
  → 운동 화면으로 복귀
```

### 걷기 자동 추적
```
운동 화면
  → 걷기 카드의 "자동" 버튼 클릭
  → WalkingTrackerScreen 열림
  → 활동 인식 권한 요청
  → 만보기 센서 시작
  → 실시간 걸음 수 표시
  → 저장하기 버튼 클릭
  → Firestore에 저장
  → 운동 화면으로 복귀
```

### 러닝 GPS 추적
```
운동 화면
  → 뛰기 카드의 "GPS 추적" 버튼 클릭
  → RunningTrackerScreen 열림
  → 위치 권한 요청
  → GPS 추적 시작
  → 실시간 거리/속도 표시
  → (선택) 일시정지/재개
  → 저장 버튼 클릭
  → 확인 다이얼로그
  → Firestore에 저장
  → 운동 화면으로 복귀
```

## 🔄 데이터 흐름

```
[센서/카메라] 
  ↓
[Service Layer]
  - PoseDetectionService
  - PedometerService  
  - RunningTrackerService
  ↓
[Stream]
  - countStream
  - stepCountStream
  - distanceStream
  ↓
[Provider Layer]
  - StreamProvider
  - StateProvider
  ↓
[UI Layer]
  - ConsumerWidget
  - ref.watch()
  ↓
[실시간 UI 업데이트]
```

## 📱 화면 구성

```
WorkoutScreen (메인 운동 화면)
├── 스쿼트 카드
│   ├── [자동] 버튼 → CameraWorkoutScreen
│   └── [+/-] 버튼 (수동 입력)
├── 런지 카드
│   ├── [자동] 버튼 → CameraWorkoutScreen
│   └── [+/-] 버튼 (수동 입력)
├── 걷기 카드
│   ├── [자동] 버튼 → WalkingTrackerScreen
│   └── [+/-] 버튼 (수동 입력)
└── 뛰기 카드
    ├── [GPS 추적] 버튼 → RunningTrackerScreen
    └── [+/-] 버튼 (수동 입력)
```

## 🎨 디자인 특징

### 색상 테마
- **스쿼트/런지**: 초록색 (#00C853)
- **걷기**: 초록색 그라데이션
- **러닝**: 주황색 그라데이션

### UI 컴포넌트
- 원형 진행 표시기 (걷기/러닝)
- 선형 진행률 바 (목표 대비)
- 실시간 카운트 오버레이 (카메라)
- 통계 카드 (시간, 속도)

## 🔒 보안 및 개인정보

- 모든 센서 데이터는 로컬에서만 처리
- 카메라 이미지는 ML Kit으로만 전송 (Google)
- 위치 데이터는 거리 계산에만 사용
- Firestore에는 집계된 결과만 저장 (거리, 걸음 수 등)

## 🚀 성능 최적화

### 카메라 처리
- 중간 해상도 사용 (ResolutionPreset.medium)
- 이미지 처리 중 중복 호출 방지 (_isProcessing 플래그)
- YUV420 포맷 사용 (효율적)

### GPS 추적
- 5m 거리 필터 (불필요한 업데이트 방지)
- 고정밀 모드 (LocationAccuracy.high)
- 비정상 데이터 필터링

### 만보기
- 센서 네이티브 스트림 사용 (배터리 효율적)
- 에러 발생 시에도 계속 추적 (cancelOnError: false)

## 📊 테스트 시나리오

### 스쿼트 인식 테스트
1. 조명이 밝은 실내에서 테스트
2. 카메라에서 2-3m 거리 유지
3. 전신이 화면에 들어오는지 확인
4. 10회 스쿼트 수행 후 카운트 확인

### 걷기 추적 테스트
1. 실내/실외에서 100걸음 걷기
2. 실시간 카운트 확인
3. 백그라운드로 전환 후 계속 걷기
4. 앱 복귀 후 카운트 확인

### 러닝 추적 테스트
1. 실외에서 GPS 신호 대기
2. 100m 달리기
3. 일시정지 후 재개
4. 거리 정확도 확인 (±10m 이내)

## 🐛 알려진 제한사항

1. **카메라 인식**
   - 조명이 어두우면 정확도 저하
   - 옷 색상이 배경과 비슷하면 인식 어려움
   - 빠른 동작은 프레임 드롭 가능

2. **만보기**
   - 일부 저가 디바이스는 센서 미지원
   - 자전거 타기 등도 걸음으로 카운트될 수 있음

3. **GPS 추적**
   - 실내에서는 정확도 매우 낮음
   - 터널, 고층 빌딩 사이에서 신호 약함
   - 배터리 소모가 큼

## 📚 참고 문서

- [Google ML Kit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection)
- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Pedometer Plugin](https://pub.dev/packages/pedometer)




