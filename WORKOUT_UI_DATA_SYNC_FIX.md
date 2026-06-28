# 스쿼트 UI 데이터 반영 문제 해결

## 🔍 문제 분석

### 증상
- 스쿼트 카메라로 운동 완료 및 저장 성공
- Firestore에 데이터 정상 저장 확인
- 앱을 껐다 켜면 Workout 화면에 0개로 표시됨
- 홈화면과 랭킹에도 데이터가 반영되지 않음

### 근본 원인
**Workout 화면의 초기 데이터 로딩 문제**

```dart
// ❌ 문제 코드
@override
Widget build(BuildContext context) {
  final currentWorkout = ref.watch(currentWorkoutStateProvider);
  
  // ref.listen은 변경사항만 감지
  // 앱 시작 시 이미 데이터가 있으면 초기 로드를 놓침
  ref.listen<AsyncValue<WorkoutModel?>>(
    todayWorkoutProvider,
    (previous, next) {
      next.whenData((workout) {
        if (workout != null && mounted) {
          if (currentWorkout.id != workout.id) {
            ref.read(currentWorkoutStateProvider.notifier).state = workout;
          }
        }
      });
    },
  );
}
```

**문제점**:
1. `ref.listen`은 **변경사항만** 감지
2. 앱 시작 시 `todayWorkoutProvider`에 이미 데이터가 있으면 초기 이벤트를 놓침
3. `currentWorkoutStateProvider`의 초기값은 모든 값이 0
4. 결과: Firestore에 데이터가 있어도 UI에 0으로 표시

## ✅ 해결 방법

### 1. Workout 화면에 초기 데이터 로딩 추가

**파일**: `lib/features/workout/presentation/workout_screen.dart`

```dart
class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // ✅ 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayWorkout();
    });
  }

  /// 오늘의 운동 데이터 초기 로드
  void _loadTodayWorkout() {
    final todayWorkout = ref.read(todayWorkoutProvider);
    todayWorkout.whenData((workout) {
      if (workout != null && mounted) {
        ref.read(currentWorkoutStateProvider.notifier).state = workout;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkout = ref.watch(currentWorkoutStateProvider);
    final todayWorkoutAsync = ref.watch(todayWorkoutProvider);
    final authState = ref.watch(authStateProvider);

    // ✅ 실시간 업데이트를 위한 listen (변경사항 감지)
    ref.listen<AsyncValue<WorkoutModel?>>(
      todayWorkoutProvider,
      (previous, next) {
        next.whenData((workout) {
          if (workout != null && mounted) {
            // 현재 상태와 다를 때만 업데이트
            final current = ref.read(currentWorkoutStateProvider);
            if (current.squatCount != workout.squatCount ||
                current.lungeCount != workout.lungeCount ||
                current.walkSteps != workout.walkSteps ||
                current.runDistance != workout.runDistance) {
              ref.read(currentWorkoutStateProvider.notifier).state = workout;
            }
          }
        });
      },
    );
    
    // ... 나머지 코드
  }
}
```

**개선사항**:
1. ✅ `initState`에서 `addPostFrameCallback` 사용
2. ✅ `_loadTodayWorkout()`로 초기 데이터 명시적 로드
3. ✅ `ref.read(todayWorkoutProvider)`로 현재 상태 즉시 확인
4. ✅ `ref.listen`은 이후 변경사항 감지용으로 유지
5. ✅ 각 필드별 비교로 불필요한 업데이트 방지

---

## 📊 데이터 흐름 분석

### Before (문제 상황)

```
[앱 시작]
  ↓
[Firestore에서 데이터 로드]
  ├─> todayWorkoutProvider: { squatCount: 50 } ✅
  └─> currentWorkoutStateProvider: { squatCount: 0 } ❌
  ↓
[WorkoutScreen 빌드]
  ├─> ref.listen 등록 (이후 변경사항만 감지)
  └─> UI 표시: 0개 ❌

[사용자가 스쿼트 추가]
  ↓
[currentWorkoutStateProvider 업데이트]
  └─> UI 표시: 1개 (하지만 기존 50개는 반영 안됨)
```

### After (해결)

```
[앱 시작]
  ↓
[Firestore에서 데이터 로드]
  ├─> todayWorkoutProvider: { squatCount: 50 } ✅
  └─> currentWorkoutStateProvider: { squatCount: 0 } (초기값)
  ↓
[WorkoutScreen initState]
  ↓
[addPostFrameCallback]
  ↓
[_loadTodayWorkout() 실행]
  ├─> ref.read(todayWorkoutProvider)
  └─> currentWorkoutStateProvider 업데이트: { squatCount: 50 } ✅
  ↓
[WorkoutScreen 빌드]
  ├─> ref.listen 등록 (이후 변경사항 감지)
  └─> UI 표시: 50개 ✅

[이후 데이터 변경]
  ↓
[ref.listen이 변경사항 감지]
  └─> currentWorkoutStateProvider 자동 업데이트
```

---

## 🏠 홈화면과 랭킹 화면

### 홈화면

#### 1. 오늘의 목표 달성 요약 ✅
**파일**: `lib/features/home/presentation/home_screen.dart`

```dart
todayWorkout.when(
  data: (workout) {
    final squat = workout?.squatCount ?? 0;  // ✅ Firestore 데이터 직접 사용
    final lunge = workout?.lungeCount ?? 0;
    final walk = workout?.walkSteps ?? 0;
    final run = workout?.runDistance ?? 0.0;
    
    // UI에 표시
  },
  loading: () => const SizedBox(),
  error: (_, __) => const SizedBox(),
),
```

**상태**: ✅ 문제 없음
- `todayWorkoutProvider`를 직접 watch
- Firestore 데이터 실시간 반영

#### 2. 이번 주 진행 현황 그래프 ⚠️ → ✅
**파일**: `lib/features/home/presentation/home_screen.dart`

**Before (문제)**:
```dart
final weeklyWorkoutProvider = FutureProvider.autoDispose<List<WorkoutModel?>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  
  // ❌ todayWorkout 변경 시 자동 갱신 안됨
  return await authState.when(/* ... */);
});
```

**문제점**:
- `FutureProvider`는 한 번만 실행
- `getWorkoutByDate`는 스냅샷 조회 (실시간 아님)
- 오늘 데이터가 변경되어도 그래프 업데이트 안됨
- 앱 재시작해야 반영

**After (해결)**:
```dart
final weeklyWorkoutProvider = FutureProvider.autoDispose<List<WorkoutModel?>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  
  // ✅ todayWorkoutProvider를 watch하여 오늘 데이터 변경 시 자동 갱신
  ref.watch(todayWorkoutProvider);
  
  return await authState.when(/* ... */);
});
```

**개선사항**:
- ✅ `ref.watch(todayWorkoutProvider)` 추가
- ✅ 오늘 데이터 변경 시 `weeklyWorkoutProvider` 자동 재실행
- ✅ 주간 그래프 실시간 업데이트
- ✅ 앱 재시작하지 않아도 즉시 반영

**동작 흐름**:
```
[스쿼트 저장]
  ↓
[todayWorkoutProvider 업데이트] (Stream)
  ↓
[weeklyWorkoutProvider 감지] (ref.watch)
  ↓
[weeklyWorkoutProvider 재실행]
  ↓
[7일 데이터 다시 조회]
  ↓
[주간 그래프 업데이트] ✅
```

### 랭킹 화면 ✅
**파일**: `lib/features/ranking/presentation/ranking_screen.dart`

**데이터 흐름**:
```
1. rankingListProvider
   ↓
2. RankingRepository.getRankings()
   ↓
3. Firestore workouts 컬렉션에서 기간별 데이터 조회
   ↓
4. userId별로 집계 (squatCount, lungeCount 등)
   ↓
5. 가중치 적용 점수 계산
   ↓
6. 정렬 및 순위 부여
   ↓
7. UI에 표시
```

**상태**: ✅ 문제 없음
- Firestore 데이터 직접 조회
- 기간별 집계 (일간/주간/월간/전체)
- 카테고리별 정렬 (종합/스쿼트/런지/걷기/뛰기)

---

## 🧪 테스트 시나리오

### 1. 초기 로딩 테스트 ✅
**시나리오**: 앱을 껐다가 다시 실행
```
✅ Before: Firestore에 스쿼트 50개 저장
✅ After: 앱 재시작
✅ Expected: Workout 화면에 50개 표시
✅ Expected: 홈화면 "오늘의 목표"에 50개 반영
✅ Expected: 홈화면 "이번 주 진행 현황" 그래프에 반영
✅ Expected: 랭킹에 50개 반영
```

### 2. 실시간 업데이트 테스트 (주간 그래프) ✅
**시나리오**: 스쿼트 추가 후 그래프 확인
```
✅ Before: 오늘 그래프 높이 30%
✅ Action: 스쿼트 20개 추가
✅ Expected: 오늘 그래프 높이 50%로 즉시 업데이트
✅ Expected: 앱 재시작 불필요
```

### 3. 카메라 저장 → 그래프 반영 테스트 ✅
**시나리오**: 카메라 화면에서 스쿼트 추적 후 저장
```
✅ 카메라 화면: 15개 카운트
✅ 저장 버튼 클릭
✅ Firestore: 기존 50 + 15 = 65개 저장
✅ Workout 화면 복귀: 65개 표시
✅ 홈화면 탭 이동: 주간 그래프 즉시 업데이트
```

### 4. 뒤로가기 자동 저장 → 그래프 반영 ✅
**시나리오**: 카메라 화면에서 뒤로가기
```
✅ 카메라 화면: 8개 카운트
✅ 뒤로가기 버튼 클릭
✅ 자동 저장: 기존 65 + 8 = 73개
✅ Workout 화면: 73개 표시
✅ 홈화면: 주간 그래프 자동 업데이트
```

### 5. 여러 날짜 그래프 테스트 ✅
**시나리오**: 이번 주 다른 날짜들도 제대로 표시되는지
```
✅ 월요일: 스쿼트 30개 저장
✅ 화요일: 스쿼트 50개 저장
✅ 수요일(오늘): 스쿼트 70개 저장
✅ Expected: 그래프에 각 날짜별 높이 차이 표시
✅ Expected: 오늘(수요일)이 녹색으로 하이라이트
```

---

## 🔍 디버깅 가이드

### 로그 확인

```bash
# Workout 화면 초기 로딩
flutter logs | grep "Loaded previous count"
flutter logs | grep "Loading today workout"

# Provider 상태 변화
flutter logs | grep "todayWorkoutProvider"
flutter logs | grep "currentWorkoutStateProvider"

# Firestore 쿼리
flutter logs | grep "getTodayWorkout"
flutter logs | grep "workoutHistoryStream"
```

### 주요 체크포인트

1. **Firestore 데이터 확인**
   ```
   Firebase Console → Firestore Database → workouts
   - userId: 현재 사용자 ID
   - date: 오늘 날짜 (Timestamp)
   - squatCount: 저장된 값
   ```

2. **Provider 상태 확인**
   ```dart
   // 디버깅용 로그 추가
   void _loadTodayWorkout() {
     final todayWorkout = ref.read(todayWorkoutProvider);
     todayWorkout.whenData((workout) {
       print('📊 Loading today workout: ${workout?.squatCount ?? 0}');
       if (workout != null && mounted) {
         ref.read(currentWorkoutStateProvider.notifier).state = workout;
         print('✅ State updated');
       }
     });
   }
   ```

3. **날짜 비교 확인**
   ```dart
   // todayWorkoutProvider의 날짜 필터링
   final isSameDay = workoutDate.year == today.year &&
       workoutDate.month == today.month &&
       workoutDate.day == today.day;
   
   print('Workout date: $workoutDate');
   print('Today: $today');
   print('Is same day: $isSameDay');
   ```

---

## 📝 Provider 구조 설명

### 1. todayWorkoutProvider (Stream)
```dart
final todayWorkoutProvider = StreamProvider.autoDispose<WorkoutModel?>((ref) {
  // Firestore에서 실시간 데이터 스트리밍
  // 오늘 날짜 필터링
  // 자동 업데이트
});
```
- **역할**: Firestore 데이터 실시간 감지
- **업데이트**: Firestore 변경 시 자동
- **사용처**: 홈화면, Workout 화면 (초기 로드)

### 2. currentWorkoutStateProvider (State)
```dart
final currentWorkoutStateProvider = StateProvider<WorkoutModel>((ref) {
  return WorkoutModel(date: DateTime.now(), userId: '');
});
```
- **역할**: 로컬 상태 관리 (UI용)
- **업데이트**: 수동 (사용자 입력, todayWorkoutProvider 변경 시)
- **사용처**: Workout 화면 (증감 버튼, 임시 저장)

### 3. rankingListProvider (Future)
```dart
final rankingListProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) async {
  // Firestore에서 기간별 데이터 조회 및 집계
});
```
- **역할**: 랭킹 데이터 조회 및 계산
- **업데이트**: Provider 파라미터 변경 시 (기간, 카테고리)
- **사용처**: 랭킹 화면

---

## ✅ 해결 요약

### 핵심 수정 2가지

#### 1. Workout 화면 초기 데이터 로딩
**파일**: `lib/features/workout/presentation/workout_screen.dart`

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadTodayWorkout();  // ← Workout 화면 초기 로드
  });
}
```

#### 2. 주간 그래프 실시간 업데이트
**파일**: `lib/providers/workout_provider.dart`

```dart
final weeklyWorkoutProvider = FutureProvider.autoDispose<List<WorkoutModel?>>((ref) async {
  // ✅ todayWorkoutProvider를 watch하여 오늘 데이터 변경 시 자동 갱신
  ref.watch(todayWorkoutProvider);  // ← 주간 그래프 자동 갱신
  
  // ... 7일 데이터 조회
});
```

### 왜 addPostFrameCallback?
1. **initState에서는 ref.read를 사용할 수 없음**
   - Provider는 build 단계 이후에만 접근 가능

2. **addPostFrameCallback은 첫 프레임 렌더링 직후 실행**
   - Provider가 초기화된 후
   - UI 빌드가 완료된 직후
   - 안전하게 ref.read 사용 가능

3. **setState를 호출하지 않아도 됨**
   - Provider 상태 변경으로 자동 리빌드

---

## 🎯 결론

**문제**: `ref.listen`만으로는 초기 데이터 로드 불가

**해결**: `initState` + `addPostFrameCallback` + `ref.read`로 초기 데이터 명시적 로드

**결과**:
- ✅ 앱 재시작 시 Firestore 데이터 정상 표시
- ✅ 홈화면 실시간 반영
- ✅ 랭킹 시스템 정상 작동
- ✅ 카메라 저장/자동 저장 모두 정상

---

## 🔧 추가 개선사항

### 1. 로딩 인디케이터
```dart
todayWorkoutAsync.when(
  data: (workout) => /* 정상 UI */,
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => Text('데이터 로드 실패: $error'),
)
```

### 2. 에러 처리 강화
```dart
void _loadTodayWorkout() {
  try {
    final todayWorkout = ref.read(todayWorkoutProvider);
    todayWorkout.whenData((workout) {
      if (workout != null && mounted) {
        ref.read(currentWorkoutStateProvider.notifier).state = workout;
      }
    });
  } catch (e, stackTrace) {
    logger.e('Failed to load today workout: $e');
    logger.e('Stack trace: $stackTrace');
  }
}
```

### 3. 오프라인 지원
- Firestore 오프라인 캐시 활용
- 로컬 저장소 백업
- 네트워크 복구 시 자동 동기화
