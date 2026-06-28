# iOS 권한 설정 개선 가이드

## 개요

iOS TestFlight에서 "운동" 탭의 **걷기 "자동"** 버튼과 **러닝 "GPS추적"** 버튼을 눌렀을 때 권한이 거부되면, 이제 사용자가 **설정으로 바로 이동**하여 권한을 활성화할 수 있습니다.

## 수정 내용

### 1. 서비스 레이어 개선

#### `pedometer_service.dart` (걷기 추적)
- **권한 상태 반환**: `bool` 대신 `PermissionStatus`를 반환하도록 변경
- **새 메서드 추가**:
  ```dart
  Future<PermissionStatus> requestPermission()
  Future<PermissionStatus> checkPermission()
  Future<PermissionStatus> startTracking()
  ```
- **권한 상태 세부 구분**: `granted`, `denied`, `permanentlyDenied` 등을 구분

#### `running_tracker_service.dart` (러닝 추적)
- **권한 상태 반환**: `bool` 대신 `PermissionStatus`를 반환하도록 변경
- **새 메서드 추가**:
  ```dart
  Future<PermissionStatus> requestPermission()
  Future<PermissionStatus> checkPermission()
  Future<PermissionStatus> startTracking()
  ```
- **위치 서비스 확인**: GPS가 꺼져있는 경우도 감지

### 2. UI 레이어 개선

#### `walking_tracker_screen.dart`
- **권한 거부 시 대화상자 표시**:
  - 권한이 필요한 이유 설명
  - "설정으로 이동" 버튼 제공
  - `openAppSettings()` 호출로 iOS 설정 앱 열기
- **UX 개선**:
  - 명확한 메시지로 사용자 안내
  - 설정 화면으로의 직접 이동 지원

#### `running_tracker_screen.dart`
- **권한 거부 시 대화상자 표시**:
  - GPS 권한 필요성 설명
  - "설정으로 이동" 버튼 제공
  - `openAppSettings()` 호출로 iOS 설정 앱 열기
- **UX 개선**:
  - 직관적인 권한 요청 플로우
  - 설정 화면으로의 원활한 전환

## 사용자 경험 플로우

### 걷기 "자동" 버튼

1. **사용자가 "자동" 버튼 클릭**
2. **앱이 활동 인식 권한 요청**
3. **권한 거부 시**:
   ```
   ┌─────────────────────────────────┐
   │   활동 인식 권한 필요          │
   │                                 │
   │  걸음 수를 측정하려면          │
   │  활동 인식 권한이 필요합니다.  │
   │  설정에서 권한을 허용해주세요. │
   │                                 │
   │    [취소]    [설정으로 이동]   │
   └─────────────────────────────────┘
   ```
4. **"설정으로 이동" 클릭**
5. **iOS 설정 앱이 자동으로 열림**
6. **사용자가 권한 활성화**
7. **앱으로 돌아와서 다시 시도**

### 러닝 "GPS추적" 버튼

1. **사용자가 "GPS추적" 버튼 클릭**
2. **앱이 위치 권한 요청**
3. **권한 거부 시**:
   ```
   ┌─────────────────────────────────┐
   │      위치 권한 필요            │
   │                                 │
   │  GPS로 러닝 거리를 측정하려면  │
   │  위치 권한이 필요합니다.        │
   │  설정에서 권한을 허용해주세요. │
   │                                 │
   │    [취소]    [설정으로 이동]   │
   └─────────────────────────────────┘
   ```
4. **"설정으로 이동" 클릭**
5. **iOS 설정 앱이 자동으로 열림**
6. **사용자가 위치 권한 활성화** (앱 사용 중 허용 권장)
7. **앱으로 돌아와서 다시 시도**

## iOS 권한 정보

### 활동 인식 (걷기)
- **권한 키**: `NSMotionUsageDescription`
- **Info.plist 설명**: "걸음 수를 측정하기 위해 모션 센서 접근이 필요합니다."
- **사용 목적**: 만보기 기능, 걸음 수 자동 카운팅

### 위치 (러닝)
- **권한 키들**:
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSLocationAlwaysUsageDescription`
- **Info.plist 설명**:
  - "러닝 중 이동 거리를 측정하기 위해 위치 정보가 필요합니다."
  - "백그라운드에서도 러닝 거리를 추적하기 위해 위치 정보가 필요합니다."
- **사용 목적**: GPS 기반 거리 측정, 러닝 경로 추적

## 권한 상태 구분

### PermissionStatus 상태
- **`granted`**: 권한이 허용됨 → 정상 작동
- **`denied`**: 권한이 거부됨 → 다시 요청 가능
- **`permanentlyDenied`**: 권한이 영구적으로 거부됨 → 설정으로 이동 필요
- **`restricted`**: 시스템 정책으로 제한됨 (예: 자녀 보호)
- **`limited`**: 제한적 권한 (iOS 14+)

## 테스트 가이드

### 1. 권한 처음 요청
```bash
# 권한 초기화 (시뮬레이터)
xcrun simctl privacy booted reset all com.yourcompany.militarytracker

# 또는 실제 기기에서: 설정 > 일반 > iPhone/iPad 전송 또는 재설정 > 재설정 > 위치 및 개인 정보 재설정
```

### 2. 권한 거부 테스트
1. 걷기 자동 추적 시도
2. "허용 안 함" 선택
3. 대화상자에서 "설정으로 이동" 선택
4. iOS 설정에서 권한 활성화
5. 앱으로 돌아와 다시 시도

### 3. 권한 영구 거부 테스트
1. 러닝 GPS 추적 시도
2. "허용 안 함" 선택
3. 다시 시도 → "허용 안 함" 선택
4. 세 번째 시도 시 대화상자 자동 표시
5. "설정으로 이동"으로 해결

## 주의사항

1. **iOS 권한 정책**: 
   - 권한을 여러 번 거부하면 iOS가 자동으로 더 이상 묻지 않음
   - 이 경우 반드시 설정 앱에서 수동으로 변경해야 함

2. **위치 권한 종류**:
   - "앱 사용 중 허용": 앱이 활성화된 상태에서만 위치 추적
   - "항상 허용": 백그라운드에서도 위치 추적 (배터리 소모 증가)
   - 러닝 추적은 "앱 사용 중 허용"으로 충분

3. **권한 설명의 중요성**:
   - Info.plist의 권한 설명은 사용자가 처음 보는 메시지
   - 명확하고 구체적인 이유를 설명해야 승인률 증가

## 향후 개선 사항

1. **권한 미리 안내하기**:
   - 첫 실행 시 튜토리얼에서 필요한 권한 미리 설명
   - "왜 필요한지" 명확히 전달

2. **권한 상태 UI 표시**:
   - 메인 화면에 권한 상태 뱃지 표시
   - 권한이 없으면 "설정하기" 버튼 제공

3. **대체 기능 제공**:
   - GPS 없이 수동 거리 입력 옵션
   - 활동 인식 없이 타이머 기반 예상 걸음 수

## 관련 파일

- `lib/services/pedometer_service.dart` - 만보기 서비스
- `lib/services/running_tracker_service.dart` - GPS 추적 서비스
- `lib/features/workout/presentation/walking_tracker_screen.dart` - 걷기 화면
- `lib/features/workout/presentation/running_tracker_screen.dart` - 러닝 화면
- `ios/Runner/Info.plist` - iOS 권한 설정

## 참고 자료

- [Apple Developer - Requesting Authorization for Core Location](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services)
- [permission_handler 패키지 문서](https://pub.dev/packages/permission_handler)
- [iOS Human Interface Guidelines - Permissions](https://developer.apple.com/design/human-interface-guidelines/patterns/accessing-private-data/)
