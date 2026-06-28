# 스쿼트/런지 카메라 저장 기능 수정

## 📋 수정 사항

### 1. 저장 실패 문제 해결

#### 문제
- 저장 버튼 클릭 시 "저장 실패" 메시지 표시
- WorkoutRepository의 `updateWorkout`과 `createWorkout` 메서드가 예외를 throw하여 상위에서 catch하지 못함

#### 해결
**파일**: `lib/repositories/workout_repository.dart`

- `updateWorkout` 메서드: 예외를 throw하는 대신 `false` 반환하도록 변경
- `createWorkout` 메서드: 예외를 throw하는 대신 `null` 반환하도록 변경
- 상세한 에러 로깅 추가 (stackTrace 포함)

```dart
// 변경 전
throw WorkoutRepositoryException(...)

// 변경 후
logger.e('Error message');
return false; // 또는 null
```

### 2. 에러 로깅 강화

**파일**: `lib/providers/workout_provider.dart`

- `addSquatCount`와 `addLungeCount` 메서드에 상세 로깅 추가
- 각 단계별 로그 출력:
  - 시작: "Adding squat/lunge count: X for user: Y"
  - 기존 운동 발견: "Existing workout found, updating from A to B"
  - 새 운동 생성: "No existing workout, creating new workout with X squats/lunges"
  - 결과: "Squat/Lunge count update result: true/false"
  - 에러: stackTrace 포함

### 3. 뒤로가기 시 자동 저장 기능 추가

#### 문제
- 뒤로가기 버튼 클릭 시 운동 카운트가 저장되지 않음
- 사용자가 명시적으로 저장 버튼을 눌러야만 저장됨

#### 해결
**파일**: `lib/features/workout/presentation/camera_workout_screen.dart`

1. **`_saveWorkoutSilently()` 메서드 추가**
   - 뒤로가기 시 조용하게 저장 (알림 없음)
   - 카운트가 0이면 저장하지 않음

2. **`_handleExit()` 메서드 추가**
   - 자동 저장 후 화면 종료
   - 뒤로가기 버튼에 연결

3. **PopScope 위젯 추가**
   - 시스템 뒤로가기 버튼(Android) 처리
   - iOS 스와이프 제스처 처리
   - `canPop: false`로 기본 동작 방지
   - `onPopInvoked`에서 `_handleExit()` 호출

### 4. 저장 실패 메시지 개선

**파일**: `lib/features/workout/presentation/camera_workout_screen.dart`

```dart
// 변경 전
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('저장 실패'),
    backgroundColor: Colors.red,
  ),
);

// 변경 후
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('$exerciseName 저장 실패. 다시 시도해주세요.'),
    backgroundColor: Colors.red,
  ),
);
```

## 🔍 동작 흐름

### 저장 버튼 클릭 시
1. 현재 세션 카운트 확인
2. 카운트가 0이면 경고 메시지 표시 후 종료
3. Firestore에 카운트 누적 저장
4. 성공 시: 성공 메시지 + 자동 화면 종료
5. 실패 시: 명확한 실패 메시지 표시 (화면 유지)

### 뒤로가기 버튼 클릭 시
1. `_handleExit()` 호출
2. `_saveWorkoutSilently()` 실행 (조용하게 저장)
3. 카운트가 0보다 크면 Firestore에 저장
4. 화면 종료

### 시스템 뒤로가기 (Android/iOS 제스처)
1. `PopScope`의 `onPopInvoked` 트리거
2. `_handleExit()` 호출
3. 자동 저장 후 화면 종료

## 📊 에러 처리 개선

### Before (예외 throw)
```dart
if (workout.id.isEmpty) {
  throw WorkoutRepositoryException(
    type: WorkoutRepositoryError.invalidData,
    message: 'Workout ID가 유효하지 않습니다',
  );
}
```

### After (안전한 false/null 반환)
```dart
if (workout.id.isEmpty) {
  logger.e('Workout ID가 유효하지 않습니다');
  return false;
}
```

## 🧪 테스트 시나리오

### 1. 저장 버튼 테스트
- [ ] 카운트 0일 때: 경고 메시지 표시
- [ ] 카운트 > 0일 때: 성공 메시지 + 자동 종료
- [ ] 네트워크 오류 시: 실패 메시지 표시

### 2. 뒤로가기 버튼 테스트
- [ ] 카운트 0일 때: 저장 없이 종료
- [ ] 카운트 > 0일 때: 자동 저장 후 종료
- [ ] 메인 화면 복귀 시 카운트 반영 확인

### 3. 시스템 뒤로가기 테스트 (Android)
- [ ] 뒤로가기 버튼: 자동 저장 후 종료
- [ ] 여러 번 세션 반복: 누적 저장 확인

### 4. iOS 제스처 테스트
- [ ] 스와이프 제스처: 자동 저장 후 종료
- [ ] 연속 세션: 누적 확인

## 🔧 개발자 노트

### 로깅 활용
```bash
# 저장 과정 추적
flutter logs | grep "Adding squat"
flutter logs | grep "Existing workout found"
flutter logs | grep "update result"

# 에러 추적
flutter logs | grep "Error"
flutter logs | grep "Stack trace"
```

### 디버깅 팁
1. Firestore Console에서 실시간 데이터 확인
2. Flutter DevTools에서 네트워크 요청 모니터링
3. Logger 레벨 조정: `Logger.level = Level.debug`

## ✅ 변경된 파일

1. `lib/repositories/workout_repository.dart` - 예외 처리 개선
2. `lib/providers/workout_provider.dart` - 로깅 강화
3. `lib/features/workout/presentation/camera_workout_screen.dart` - 자동 저장 기능

## 📝 향후 개선 사항

- [ ] 오프라인 모드 지원 (로컬 저장 후 동기화)
- [ ] 저장 중 로딩 인디케이터 표시
- [ ] 저장 실패 시 재시도 로직
- [ ] 운동 세션 이력 저장 (각 세션별 기록)
