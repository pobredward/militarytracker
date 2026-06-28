# 밀리터리트래커 (Military Tracker)

Flutter + Firebase 기반 군사 훈련 트래커 모바일 애플리케이션

> **🎯 실무 수준의 아키텍처 적용:** Riverpod + Freezed + MVVM 패턴

## 주요 기능

- 🏃‍♂️ **운동 트래킹**: 스쿼트, 런지, 걷기, 달리기 등 다양한 운동 기록
- 👥 **커뮤니티**: 사용자 간 소통 및 정보 공유
- 📊 **통계**: 운동 기록 및 진행 상황 분석
- 🔔 **푸시 알림**: 운동 리마인더 및 커뮤니티 알림
- 🔐 **소셜 로그인**: Google 로그인 및 이메일/비밀번호 로그인

## 기술 스택

### Frontend
- **Flutter**: 3.x
- **State Management**: Riverpod 2.6.x
- **Immutable Models**: Freezed 2.5.x
- **Architecture**: MVVM Pattern
- **Routing**: Go Router 13.x

### Backend & Services
- **Firebase**
  - Authentication (Email/Password, Google)
  - Cloud Firestore (실시간 데이터베이스)
  - Cloud Messaging (푸시 알림)
  - Cloud Storage (파일 저장)
- **HTTP Client**: Dio 5.x
- **Local Storage**: SharedPreferences

### Development Tools
- **Code Generation**: build_runner
- **Logging**: Logger
- **Linting**: flutter_lints, riverpod_lint, custom_lint

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점 (ProviderScope + AuthGate)
├── firebase_options.dart              # Firebase 설정
│
├── core/                              # 핵심 유틸리티
│   ├── config/                       # 설정 파일
│   │   ├── constants.dart           # 앱 상수
│   │   ├── logger.dart              # 로깅
│   │   └── app_router.dart          # 라우팅
│   ├── network/                      # 네트워크
│   │   └── dio_client.dart          # HTTP 클라이언트
│   ├── database/                     # 로컬 DB
│   │   └── local_storage.dart       # SharedPreferences
│   └── utils/                        # 유틸리티
│       ├── date_formatter.dart      # 날짜 포맷
│       └── validators.dart          # 검증 로직
│
├── models/                            # Freezed 모델
│   ├── user_model.dart               # 사용자 모델
│   ├── workout_model.dart            # 운동 기록 모델
│   └── post_model.dart               # 게시글 모델
│
├── repositories/                      # Repository 패턴
│   ├── auth_repository.dart          # 인증 레포지토리
│   ├── workout_repository.dart       # 운동 레포지토리
│   └── post_repository.dart          # 게시글 레포지토리
│
├── providers/                         # Riverpod Providers
│   ├── auth_provider.dart            # 인증 상태 관리
│   ├── workout_provider.dart         # 운동 상태 관리
│   ├── post_provider.dart            # 게시글 상태 관리
│   └── theme_provider.dart           # 테마 상태 관리
│
├── features/                          # 기능별 모듈 (MVVM)
│   ├── auth/                         # 인증 기능
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── login_screen.dart    # 로그인 화면
│   │       └── signup_screen.dart   # 회원가입 화면
│   ├── home/                         # 홈 기능
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── home_screen.dart     # 홈 화면
│   ├── community/                    # 커뮤니티 기능
│   │   └── presentation/
│   │       └── community_screen.dart
│   ├── workout/                      # 운동 기능
│   │   └── presentation/
│   │       └── workout_screen.dart  # 운동 체크 화면
│   └── profile/                      # 프로필 기능
│       └── presentation/
│           └── profile_screen.dart  # 프로필 화면
│
└── widgets/                           # 공통 위젯
```

## 시작하기

### 사전 요구사항

- Flutter SDK 3.0 이상
- Dart SDK 3.0 이상
- Android Studio / Xcode
- Firebase 프로젝트 설정

### 설치 및 실행

1. **저장소 클론 (선택사항)**
```bash
# git clone <repository-url>
cd militarytracker
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **Freezed 코드 생성**
```bash
# 한 번만 실행
flutter pub run build_runner build --delete-conflicting-outputs

# 또는 개발 중 자동 생성 (watch 모드)
flutter pub run build_runner watch --delete-conflicting-outputs
```

4. **Firebase 설정**

Firebase 연동을 위해서는 별도의 설정이 필요합니다. 자세한 내용은 [FIREBASE_SETUP.md](FIREBASE_SETUP.md)를 참고하세요.

필수 파일:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

5. **iOS 의존성 설치** (iOS 빌드 시)
```bash
cd ios
pod install
cd ..
```

6. **앱 실행**
```bash
# 연결된 기기에서 실행
flutter run

# 특정 기기 선택
flutter devices
flutter run -d <device_id>
```

## Firebase 구성

### 인증 (Authentication)
- **이메일/비밀번호 로그인**: 사용자 등록 및 로그인
- **Google 로그인**: 간편한 소셜 로그인
- **자동 로그인**: 세션 유지 및 자동 로그인

### 데이터베이스 (Firestore)

#### Users Collection
```
users/{userId}
├── email: string
├── displayName: string
├── photoUrl: string?
├── authProvider: string (email | google)
├── totalSquats: number
├── totalLunges: number
├── totalWalkSteps: number
├── totalRunDistance: number
├── workoutDays: number
├── createdAt: timestamp
└── lastLoginAt: timestamp
```

#### Workouts Collection
```
workouts/{workoutId}
├── id: string
├── userId: string
├── squatCount: number
├── lungeCount: number
├── walkSteps: number
├── runDistance: number (km)
├── duration: number (seconds)
├── notes: string?
├── date: timestamp
├── createdAt: timestamp
└── updatedAt: timestamp
```

## 아키텍처 상세

### MVVM 패턴
- **Model**: Freezed로 불변 데이터 모델 정의
- **View**: Flutter Widget (ConsumerWidget)
- **ViewModel**: Riverpod Provider

### Repository 패턴
데이터 소스를 추상화하여 비즈니스 로직과 분리:

```dart
// Repository 정의
class WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<WorkoutModel?> getTodayWorkout(String userId) async {
    // Firestore 연동
  }
  
  Future<String?> createWorkout(WorkoutModel workout) async {
    // 운동 기록 생성
  }
}

// Provider로 제공
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});
```

### Riverpod 상태 관리

```dart
// Stream Provider (실시간 데이터)
final todayWorkoutProvider = StreamProvider.autoDispose<WorkoutModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(workoutRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return repository.workoutHistoryStream(user.uid, limit: 1);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// UI에서 사용
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(todayWorkoutProvider);
    
    return workout.when(
      data: (data) => Text('오늘의 운동: ${data?.squatCount ?? 0}회'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('에러: $err'),
    );
  }
}
```

### Freezed 불변 모델

```dart
@freezed
class WorkoutModel with _$WorkoutModel {
  const factory WorkoutModel({
    @Default('') String id,
    @Default('') String userId,
    @Default(0) int squatCount,
    @Default(0) int lungeCount,
    @Default(0) int walkSteps,
    @Default(0.0) double runDistance,
    required DateTime date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WorkoutModel;

  factory WorkoutModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModelFromJson(json);
}

// 사용
final workout = WorkoutModel(date: DateTime.now(), userId: 'user123');
final updated = workout.copyWith(squatCount: 100); // 불변 업데이트
```

## 주요 기능 구현

### 1. 인증 시스템

- **로그인/회원가입**: 이메일 또는 Google 계정으로 가입
- **인증 가드**: 로그인하지 않은 사용자는 로그인 화면으로 리다이렉트
- **자동 로그인**: Firebase Auth의 세션 관리

```dart
// AuthGate: 인증 상태에 따라 화면 전환
class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) => user == null ? LoginScreen() : MainScreen(),
      loading: () => LoadingScreen(),
      error: (err, _) => ErrorScreen(error: err),
    );
  }
}
```

### 2. 운동 기록 시스템

- **실시간 동기화**: Firestore Stream으로 실시간 데이터 업데이트
- **오늘의 운동**: 날짜별 운동 기록 조회 및 수정
- **운동 통계**: 사용자별 전체 운동 통계 집계

```dart
// 운동 저장
final workoutActions = ref.read(workoutActionProvider);
await workoutActions.saveOrUpdateTodayWorkout(
  squatCount: 100,
  lungeCount: 50,
  walkSteps: 10000,
  runDistance: 5.0,
);
```

### 3. 프로필 관리

- **사용자 정보 표시**: 이름, 이메일, 프로필 사진
- **운동 통계**: 총 운동일, 스쿼트, 런지, 걷기, 달리기 통계
- **로그아웃/계정 삭제**: 계정 관리 기능

## 빌드

### Android APK 빌드
```bash
flutter build apk --release
```

### iOS 빌드
```bash
flutter build ios --release
```

## 개발 가이드

### 새로운 모델 추가
1. `lib/models/my_model.dart` 생성
2. Freezed 어노테이션 추가
3. 코드 생성 실행:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 새로운 기능 추가 (MVVM)
1. `lib/features/my_feature/` 폴더 생성
2. 하위 폴더 구성:
   - `data/`: Repository, DataSource
   - `domain/`: UseCase, Entity
   - `presentation/`: Screen, ViewModel
3. Provider 작성: `lib/providers/my_feature_provider.dart`

### 코드 스타일
```bash
# 코드 분석
flutter analyze

# 코드 포맷
flutter format lib/
```

## 개발 상태

### ✅ 완료
- [x] 기본 UI 구조
- [x] MVVM 아키텍처 적용
- [x] Riverpod 상태 관리 구현
- [x] Freezed 모델 구현
- [x] Repository 패턴 적용
- [x] Firebase 연동 (Authentication, Firestore)
- [x] 로깅 및 유틸리티 구현
- [x] 이메일/비밀번호 로그인 구현
- [x] Google 소셜 로그인 구현
- [x] 운동 데이터 CRUD 구현
- [x] 실시간 데이터 동기화 (Stream)
- [x] 사용자 프로필 관리
- [x] 운동 통계 기능

### 🚧 추후 구현 예정
- [ ] Apple 로그인 (iOS)
- [ ] 커뮤니티 게시글 CRUD 기능
- [ ] 댓글 및 좋아요 기능
- [ ] 푸시 알림 구현 (FCM)
- [ ] 운동 히스토리 상세 보기
- [ ] 달력 뷰로 운동 기록 확인
- [ ] 업적 시스템
- [ ] 친구 기능 및 랭킹
- [ ] 운동 타이머 및 카운터
- [ ] Unit & Widget 테스트
- [ ] CI/CD 파이프라인

## 화면 구성

### 1. 인증 화면
- **로그인**: 이메일/비밀번호, Google 로그인
- **회원가입**: 이메일/비밀번호 회원가입
- **비밀번호 재설정** (추후)

### 2. 홈 화면
- 오늘의 운동 요약
- 목표 대비 진행률 표시
- 스쿼트, 런지, 걷기, 달리기 현황

### 3. 커뮤니티 화면
- 게시글 목록
- 좋아요 및 댓글 기능 (예정)
- 게시글 작성 (예정)

### 4. 운동 체크 화면
- 스쿼트 카운터 (증가/감소)
- 런지 카운터 (증가/감소)
- 걷기 걸음 수 (증가/감소)
- 달리기 거리 측정 (km)
- 진행률 표시 (프로그레스 바)
- Firebase 실시간 저장

### 5. 프로필 화면
- 사용자 정보 (이름, 이메일, 프로필 사진)
- 전체 운동 통계 (총 운동일, 스쿼트, 런지, 걷기, 달리기)
- 로그아웃
- 계정 삭제

## 문서

- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Firebase 설정 가이드
- [ARCHITECTURE.md](ARCHITECTURE.md) - 아키텍처 상세 설명 (추후)
- [GETTING_STARTED.md](GETTING_STARTED.md) - 실행 가이드 (추후)

## 문제 해결

### 빌드 오류
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Firebase 연결 오류
- `google-services.json` (Android) 또는 `GoogleService-Info.plist` (iOS) 파일이 올바른 위치에 있는지 확인
- Firebase 콘솔에서 SHA-1 인증서가 등록되어 있는지 확인 (Google 로그인 사용 시)

## 라이선스

이 프로젝트는 개인 프로젝트입니다.

## 문의

문제가 발생하거나 제안사항이 있으시면 이슈를 등록해주세요.

