# 밀리터리트래커 - 실무 아키텍처 업그레이드 완료 ✨

## 🎯 적용된 실무 기술 스택

### 1. **Riverpod (State Management)**
- Flutter 공식 팀이 추천하는 차세대 상태 관리
- Provider보다 안전하고 테스트하기 쉬운 구조
- 컴파일 타임 안정성 보장

### 2. **Freezed (Immutable Models)**
- 불변 데이터 모델 자동 생성
- copyWith, toString, equality 자동 구현
- JSON 직렬화/역직렬화 지원

### 3. **MVVM Architecture**
- Model-View-ViewModel 패턴 적용
- 비즈니스 로직과 UI 분리
- 유지보수성과 테스트 용이성 향상

### 4. **Repository Pattern**
- 데이터 소스 추상화
- Firebase, API, Local Storage 등 다양한 소스 통합 관리

### 5. **Go Router**
- 선언적 라우팅
- Deep linking 지원
- Web 지원 최적화

### 6. **기타 실무 도구들**
- **Dio**: HTTP 클라이언트 (인터셉터, 로깅 지원)
- **Logger**: 구조화된 로깅
- **SharedPreferences**: 로컬 저장소
- **Intl**: 다국어 및 날짜 포맷팅

---

## 📂 새로운 폴더 구조

```
lib/
├── main.dart                          # 앱 진입점 (ProviderScope 적용)
├── firebase_options.dart              # Firebase 설정
│
├── core/                              # 핵심 유틸리티
│   ├── config/
│   │   ├── constants.dart            # 앱 상수
│   │   ├── logger.dart               # 로깅 설정
│   │   └── app_router.dart           # Go Router 설정
│   ├── network/
│   │   └── dio_client.dart           # Dio HTTP 클라이언트
│   ├── database/
│   │   └── local_storage.dart        # SharedPreferences 래퍼
│   └── utils/
│       ├── date_formatter.dart       # 날짜 포맷 유틸
│       └── validators.dart           # 입력값 검증
│
├── models/                            # Freezed 모델
│   ├── user_model.dart               # 사용자 모델
│   ├── workout_model.dart            # 운동 기록 모델
│   └── post_model.dart               # 게시글 모델
│
├── repositories/                      # Repository 패턴
│   ├── auth_repository.dart          # 인증 관련
│   ├── workout_repository.dart       # 운동 기록 관련
│   └── post_repository.dart          # 게시글 관련
│
├── providers/                         # Riverpod Providers
│   ├── auth_provider.dart            # 인증 상태
│   ├── workout_provider.dart         # 운동 상태
│   ├── post_provider.dart            # 게시글 상태
│   └── theme_provider.dart           # 테마 상태
│
├── features/                          # 기능별 모듈 (MVVM)
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart
│   ├── community/
│   │   └── presentation/
│   │       └── community_screen.dart
│   ├── workout/
│   │   └── presentation/
│   │       └── workout_screen.dart
│   └── profile/
│       └── presentation/
│           └── profile_screen.dart
│
└── widgets/                           # 공통 위젯 (필요시 추가)
```

---

## 🚀 사용 방법

### 1. 의존성 설치
```bash
flutter pub get
```

### 2. Freezed 코드 생성
```bash
# 한 번만 실행
flutter pub run build_runner build --delete-conflicting-outputs

# 파일 변경 감지하여 자동 생성 (개발 중)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. 앱 실행
```bash
flutter run
```

---

## 📝 주요 변경 사항

### Before (기본 구조)
```dart
// 단순 StatefulWidget
class HomeScreen extends StatefulWidget {
  // ...
}

// Provider로 상태 관리
final myProvider = Provider((ref) => MyService());
```

### After (실무 구조)
```dart
// Riverpod ConsumerWidget
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
    // ...
  }
}

// Freezed 불변 모델
@freezed
class WorkoutModel with _$WorkoutModel {
  const factory WorkoutModel({
    required int squatCount,
    required int lungeCount,
  }) = _WorkoutModel;
  
  factory WorkoutModel.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModelFromJson(json);
}

// Repository 패턴
class WorkoutRepository {
  Future<WorkoutModel?> getTodayWorkout(String userId) async {
    // Firebase Firestore 연동
  }
}

// Riverpod Provider
final workoutProvider = FutureProvider.autoDispose<WorkoutModel?>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getTodayWorkout(userId);
});
```

---

## 🎨 Riverpod 사용 예시

### 1. 데이터 읽기
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider 구독
    final user = ref.watch(currentUserProvider);
    
    return user.when(
      data: (user) => Text(user?.displayName ?? '게스트'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('에러: $err'),
    );
  }
}
```

### 2. 상태 업데이트
```dart
// StateProvider 업데이트
ref.read(currentWorkoutStateProvider.notifier).state = 
    currentWorkout.copyWith(squatCount: 100);

// FutureProvider 새로고침
ref.invalidate(postsProvider);
```

### 3. Repository 사용
```dart
final workoutRepository = ref.watch(workoutRepositoryProvider);
await workoutRepository.saveWorkout(userId, workout);
```

---

## 🏗️ Freezed 모델 수정 방법

### 1. 모델 파일 수정
```dart
// lib/models/my_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
    @Default(0) int count,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

### 2. 코드 생성 실행
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🔥 Firebase 연동 준비 완료

Repository 패턴으로 Firebase 연동이 준비되어 있습니다:

- ✅ `AuthRepository`: Firebase Auth 연동
- ✅ `WorkoutRepository`: Firestore 운동 기록 저장
- ✅ `PostRepository`: Firestore 커뮤니티 게시글

실제 로그인 구현 시:
```dart
final authRepo = ref.watch(authRepositoryProvider);
await authRepo.signInWithEmail(email, password);
```

---

## 📚 추가 학습 자료

### Riverpod
- [공식 문서](https://riverpod.dev)
- [한글 가이드](https://riverpod.dev/ko/)

### Freezed
- [GitHub](https://github.com/rrousselGit/freezed)
- [사용 예시](https://pub.dev/packages/freezed)

### Flutter Clean Architecture
- [Reference](https://javaexpert.tistory.com/1085)

---

## 🎯 다음 구현 단계

1. **로그인 UI 구현** (`features/auth/presentation/`)
2. **Firebase Auth 실제 연동**
3. **Firestore CRUD 구현**
4. **푸시 알림 (FCM)**
5. **Unit Test 작성** (`test/` 폴더)
6. **Widget Test 작성**

---

## 💡 팁

### 개발 중 watch 모드 사용
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Provider 디버깅
```dart
// main.dart에 ProviderObserver 추가
ProviderScope(
  observers: [MyObserver()],
  child: MyApp(),
)
```

### Freezed 코드 충돌 해결
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## ✅ 실무 수준 체크리스트

- [x] Riverpod 상태 관리
- [x] Freezed 불변 모델
- [x] MVVM 아키텍처
- [x] Repository 패턴
- [x] Dio HTTP 클라이언트
- [x] Logger 구조화된 로깅
- [x] SharedPreferences 래퍼
- [x] 날짜/검증 유틸리티
- [x] Go Router 준비
- [x] Firebase 연동 준비
- [x] 확장 가능한 폴더 구조

---

이제 실무에서 사용하는 수준의 Flutter 아키텍처를 갖추었습니다! 🎉

코드를 확장하거나 새로운 기능을 추가할 때 이 구조를 따라 개발하면 됩니다.





