# Firestore 타입 변환 전체 수정 완료

> 작성일: 2026-03-23  
> 상태: ✅ 완료

## 📋 개요

Firestore의 모든 날짜 필드 처리를 통합하여 타입 안정성과 일관성을 확보했습니다.

## 🔧 해결 방법

### 1. 공통 유틸리티 클래스 생성

`lib/core/utils/firestore_type_converter.dart`

```dart
class FirestoreTypeConverter {
  /// 날짜 → milliseconds 변환
  /// Timestamp, String(ISO 8601), int 모두 처리
  static int? dateToMillis(dynamic field, {String fieldName = 'date'})
  
  /// 날짜 → DateTime 변환
  static DateTime? dateToDateTime(dynamic field, {String fieldName = 'date'})
  
  /// Timestamp → ISO 8601 문자열 변환
  static String? timestampToIso8601(dynamic field, {String fieldName = 'timestamp'})
}
```

### 2. 적용된 Repository

#### ✅ workout_repository.dart
- `getTodayWorkout()` - line 115-117
- `getWorkoutByDate()` - line 159-161
- `getWorkoutHistory()` - line 287-289
- `workoutHistoryStream()` - line 322-372

#### ✅ follow_repository.dart  
- `getUserProfile()` - line 124-126
- `_calculateStreak()` - line 179-181

#### ✅ auth_repository.dart
- `getUserInfo()` - line 45-46
- `userInfoStream()` - line 66-67

#### ✅ ranking_repository.dart
- `getRankings()` - line 70

## 📊 수정 통계

| Repository | 수정 위치 | Before | After |
|------------|-----------|---------|--------|
| workout_repository | 4곳 | `as Timestamp?` | `FirestoreTypeConverter` |
| follow_repository | 2곳 | `as Timestamp?` | `FirestoreTypeConverter` |
| auth_repository | 2곳 | `as Timestamp?` | `FirestoreTypeConverter` |
| ranking_repository | 1곳 | `as Timestamp?` | `FirestoreTypeConverter` |
| **총계** | **9곳** | - | - |

## 💡 장점

### 1. 타입 안정성
```dart
// ❌ Before: 런타임 에러 가능
'date': (data['date'] as Timestamp?)?.millisecondsSinceEpoch

// ✅ After: 모든 타입 안전하게 처리
'date': FirestoreTypeConverter.dateToMillis(data['date'])
```

### 2. 코드 재사용
- 중복된 타입 변환 로직 제거
- 한 곳에서 관리 → 유지보수 용이
- 버그 수정 시 한 번만 수정

### 3. 에러 핸들링
```dart
try {
  return DateTime.parse(field).millisecondsSinceEpoch;
} catch (e) {
  AppLogger.e('Failed to parse date string: $field', e);
  return null;
}
```

### 4. 로깅
- 필드명을 파라미터로 받아 명확한 에러 로그
- 디버깅 시 어떤 필드에서 문제가 발생했는지 즉시 파악

## 🎯 지원하는 타입

### 날짜 필드 (date, createdAt, updatedAt)
| 타입 | 예시 | 처리 방법 |
|------|------|-----------|
| **Timestamp** | Firestore 네이티브 | `field.millisecondsSinceEpoch` |
| **String** | `"2025-12-19T00:54:11.329"` | `DateTime.parse().millisecondsSinceEpoch` |
| **int** | `1734567851329` | 그대로 사용 |
| **null** | `null` | `null` 반환 |

### ISO 8601 변환 (createdAt, lastLoginAt for UserModel)
| 타입 | 처리 방법 |
|------|-----------|
| **Timestamp** | `toDate().toIso8601String()` |
| **String** | `DateTime.parse().toIso8601String()` (검증) |
| **int** | `DateTime.fromMilliseconds().toIso8601String()` |

## 🧪 테스트 시나리오

### 1. Timestamp 데이터
```dart
// Firestore에서
{ 'date': Timestamp.now() }

// 결과
✅ 정상 변환: millisecondsSinceEpoch
```

### 2. String 데이터
```dart
// Firestore에서 (기존 데이터)
{ 'date': "2025-12-19T00:54:11.329" }

// 결과
✅ 정상 변환: DateTime.parse → milliseconds
```

### 3. int 데이터
```dart
// Firestore에서
{ 'date': 1734567851329 }

// 결과
✅ 정상 사용: 그대로 반환
```

### 4. 잘못된 데이터
```dart
// Firestore에서
{ 'date': "invalid-date" }

// 결과
⚠️ 로그 출력 + null 반환
```

## 📝 사용 예시

### Before (각 Repository마다 중복)
```dart
return WorkoutModel.fromJson({
  ...data,
  'id': doc.id,
  'date': (data['date'] as Timestamp?)?.millisecondsSinceEpoch,
  'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
  'updatedAt': (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch,
});
```

### After (통합된 유틸리티)
```dart
return WorkoutModel.fromJson({
  ...data,
  'id': doc.id,
  'date': FirestoreTypeConverter.dateToMillis(data['date'], fieldName: 'date'),
  'createdAt': FirestoreTypeConverter.dateToMillis(data['createdAt'], fieldName: 'createdAt'),
  'updatedAt': FirestoreTypeConverter.dateToMillis(data['updatedAt'], fieldName: 'updatedAt'),
});
```

## 🎉 결과

### Before
- ❌ 타입 에러 발생 (String → Timestamp 캐스팅 실패)
- ❌ 9곳에서 중복된 타입 캐스팅 코드
- ❌ 일관되지 않은 에러 처리
- ❌ 디버깅 어려움

### After
- ✅ 모든 타입 안전하게 처리
- ✅ 1개의 유틸리티 클래스로 통합
- ✅ 일관된 에러 처리 및 로깅
- ✅ 명확한 에러 메시지

## 🚀 향후 권장 사항

### Firestore 저장 시 타입 통일
```dart
// ✅ 권장: 항상 Timestamp 사용
await _firestore.collection('workouts').doc(id).set({
  'date': Timestamp.fromDate(workout.date),
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});

// ❌ 비권장: String이나 int 사용
await _firestore.collection('workouts').doc(id).set({
  'date': workout.date.toIso8601String(), // String
  'createdAt': DateTime.now().millisecondsSinceEpoch, // int
});
```

### 새로운 날짜 필드 추가 시
```dart
// 항상 FirestoreTypeConverter 사용
'newDateField': FirestoreTypeConverter.dateToMillis(
  data['newDateField'], 
  fieldName: 'newDateField'
),
```

## ✅ 체크리스트

- [x] FirestoreTypeConverter 유틸리티 생성
- [x] workout_repository.dart 수정 (4곳)
- [x] follow_repository.dart 수정 (2곳)
- [x] auth_repository.dart 수정 (2곳)
- [x] ranking_repository.dart 수정 (1곳)
- [x] 에러 핸들링 추가
- [x] 로깅 추가
- [x] 문서화 완료
- [x] 테스트 시나리오 검증

**모든 Firestore 타입 불일치 문제 해결 완료! 🎉**
