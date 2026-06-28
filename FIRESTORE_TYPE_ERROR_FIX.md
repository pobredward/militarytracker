# Firestore 데이터 타입 불일치 에러 수정

> 작성일: 2026-03-23  
> 상태: ✅ 해결 완료

## 🐛 문제 상황

앱 실행 시 workout 데이터를 불러오는 과정에서 타입 에러 발생:

```
⛔ Error parsing workout doc pgcogHoEEvr6FLc7tOL4: 
TypeError: "2025-12-19T00:54:11.329": type 'String' is not a subtype of type 'Timestamp?'
```

## 🔍 원인 분석

### 문제점
Firestore에 저장된 날짜 필드가 **3가지 다른 형태**로 존재:
1. **Timestamp** (Firestore 네이티브 타입)
2. **String** (ISO 8601 형식: `"2025-12-19T00:54:11.329"`)
3. **int** (millisecondsSinceEpoch)

### 기존 코드의 문제
```dart
// ❌ Timestamp만 처리 가능
'date': (data['date'] as Timestamp?)?.millisecondsSinceEpoch,
```

이 코드는 String이나 int 타입의 날짜를 처리하지 못해 에러 발생.

## ✅ 해결 방법

### 개선된 코드
모든 타입을 처리할 수 있도록 타입 체크 로직 추가:

```dart
// date 필드 타입 확인 및 변환
int? dateMillis;
final dateField = data['date'];

if (dateField is Timestamp) {
  // Firestore Timestamp → milliseconds
  dateMillis = dateField.millisecondsSinceEpoch;
} else if (dateField is String) {
  // ISO 8601 String → DateTime → milliseconds
  try {
    dateMillis = DateTime.parse(dateField).millisecondsSinceEpoch;
  } catch (e) {
    logger.e('Failed to parse date string: $dateField');
    dateMillis = DateTime.now().millisecondsSinceEpoch;
  }
} else if (dateField is int) {
  // 이미 milliseconds 형태
  dateMillis = dateField;
}
```

### 적용된 필드
- ✅ `date` (required)
- ✅ `createdAt` (nullable)
- ✅ `updatedAt` (nullable)

## 🎯 효과

### Before
```
⛔ TypeError 발생
❌ 앱 실행 직후 workout 데이터 로드 실패
❌ 홈 화면에 운동 기록이 표시되지 않음
```

### After
```
✅ 모든 날짜 타입 정상 처리
✅ workout 데이터 정상 로드
✅ 홈 화면에 운동 기록 표시
✅ 에러 로그 없음
```

## 📝 추가 개선 사항

### 1. 에러 핸들링 강화
```dart
try {
  dateMillis = DateTime.parse(dateField).millisecondsSinceEpoch;
} catch (e) {
  logger.e('Failed to parse date string: $dateField');
  dateMillis = DateTime.now().millisecondsSinceEpoch; // fallback
}
```

### 2. Fallback 처리
파싱 실패 시 기본값으로 대체하여 앱 크래시 방지:
```dart
return WorkoutModel(
  id: doc.id,
  userId: userId,
  date: DateTime.now(), // fallback
);
```

## 🔧 수정된 파일

- `lib/repositories/workout_repository.dart` (line 317-338)

## 💡 교훈

### 문제의 근본 원인
1. Firestore에 데이터를 저장할 때 일관되지 않은 타입 사용
2. 코드에서 단일 타입만 가정

### 해결 전략
1. **타입 체크**: `is` 키워드로 런타임 타입 확인
2. **다형성 처리**: 여러 타입을 모두 처리할 수 있는 로직
3. **방어적 프로그래밍**: try-catch와 fallback으로 에러 방지
4. **로깅**: 각 분기에서 상세한 로그 출력

### 향후 개선 방안
```dart
// Firestore에 저장할 때 타입 통일
await _firestore.collection('workouts').doc(id).set({
  'date': Timestamp.fromDate(workout.date), // ✅ 항상 Timestamp
  'createdAt': FieldValue.serverTimestamp(), // ✅ 서버 타임스탬프
  // ...
});
```

## ✅ 테스트 결과

### 시나리오별 테스트
1. ✅ Timestamp 형태 데이터 → 정상 처리
2. ✅ String (ISO 8601) 형태 데이터 → 정상 변환
3. ✅ int (milliseconds) 형태 데이터 → 정상 처리
4. ✅ 잘못된 String 형태 → fallback 처리
5. ✅ null 값 → nullable 처리

### 로그 확인
```
✅ 💡 Starting workout history stream for user: xxx
✅ 💡 Received 1 workout documents
✅ 🐛 Processing workout doc: xxx
✅ (에러 없음)
```

## 🎉 결론

**문제**: Firestore 데이터 타입 불일치로 인한 런타임 에러  
**해결**: 다형성 타입 체크 및 변환 로직 추가  
**결과**: 모든 날짜 형식을 안전하게 처리, 앱 안정성 향상
