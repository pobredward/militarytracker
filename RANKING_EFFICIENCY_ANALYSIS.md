# 랭킹 시스템 효율성 분석 - 언제 rankings DB가 필요한가?

## 🎯 핵심 질문

> "rankings DB를 만드는 게 정말 더 효율적인가?"

**답변**: 사용자 수와 조회 빈도에 따라 다릅니다!

---

## 📊 시나리오별 분석

### 시나리오 1: 사용자 수 적음 (< 100명)

#### 현재 방식 (workouts에서 집계)

```dart
// 월간 스쿼트 랭킹 조회
final workouts = await _firestore
  .collection('workouts')
  .where('date', isGreaterThanOrEqualTo: thisMonth)
  .get(); // 50명 × 20회 = 1,000개 문서

// 집계
Map<String, int> userSquats = {};
for (var doc in workouts.docs) {
  userSquats[doc['userId']] = (userSquats[doc['userId']] ?? 0) + doc['squatCount'];
}
// 정렬
```

**비용**:
- 읽기: 1,000개 (오늘만)
- DAU 100명 × 10회 조회 = 10,000 reads/day
- **월간: 300,000 reads = 무료!** (무료 할당량: 50,000 reads/day)

**결론**: 사용자 100명 이하면 **현재 방식으로도 충분!**

---

### 시나리오 2: 사용자 수 중간 (100-1,000명)

#### 현재 방식

```
월간 랭킹 조회:
- workouts: 500명 × 20회 = 10,000개
- DAU 500명 × 10회 = 50,000,000 reads/day
- 월간: 1,500,000,000 reads
- 비용: $90/월
```

#### rankings 방식

```
월간 랭킹 조회:
- rankings/monthly/2024-01: 500개
- DAU 500명 × 10회 = 2,500,000 reads/day
- 월간: 75,000,000 reads
- 비용: $4.50/월 (쓰기 비용 포함)
```

**결론**: 사용자 100명 이상이면 **rankings 방식이 유리!**

---

### 시나리오 3: 사용자 수 많음 (> 1,000명)

#### 현재 방식

```
월간 랭킹 조회:
- workouts: 1,000명 × 20회 = 20,000개
- DAU 1,000명 × 10회 = 200,000,000 reads/day
- 월간: 6,000,000,000 reads
- 비용: $360/월
```

#### rankings 방식

```
월간 랭킹 조회:
- rankings/monthly/2024-01: 1,000개 (상위 100명만 보여주면 100개!)
- DAU 1,000명 × 10회 = 1,000,000 reads/day (상위 100명만 표시)
- 월간: 30,000,000 reads
- 비용: $2/월
```

**결론**: 사용자 1,000명 이상이면 **rankings 방식 필수!**

---

## 💡 더 간단한 방법: 하이브리드

"내 코드에서 직접 rankings에 쓰면 되잖아" ← 정답!

### Flutter에서 직접 rankings 업데이트 (Functions 불필요!)

```dart
class WorkoutRepository {
  Future<String?> createWorkout(WorkoutModel workout) async {
    try {
      final batch = _firestore.batch();
      
      // 1. workouts 컬렉션에 저장
      final workoutRef = _firestore.collection('workouts').doc();
      final workoutData = workout.toJson();
      workoutData['createdAt'] = FieldValue.serverTimestamp();
      batch.set(workoutRef, workoutData);
      
      // 2. rankings 컬렉션도 동시 업데이트
      await _updateRankings(batch, workout);
      
      // 3. 한 번에 커밋
      await batch.commit();
      
      return workoutRef.id;
    } catch (e) {
      logger.e('Workout 생성 실패: $e');
      return null;
    }
  }
  
  Future<void> _updateRankings(WriteBatch batch, WorkoutModel workout) async {
    final userId = workout.userId;
    final date = workout.date;
    
    // 사용자 정보 조회
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final displayName = userDoc.data()?['displayName'] ?? '사용자';
    final photoUrl = userDoc.data()?['photoUrl'];
    
    // 종합 점수 계산
    final overallScore = _calculateOverallScore(workout);
    
    // 일간 랭킹
    final dailyKey = _formatDate(date, 'YYYY-MM-DD');
    final dailyRef = _firestore
      .collection('rankings')
      .doc('daily')
      .collection(dailyKey)
      .doc(userId);
    
    batch.set(dailyRef, {
      'squatCount': FieldValue.increment(workout.squatCount),
      'lungeCount': FieldValue.increment(workout.lungeCount),
      'walkSteps': FieldValue.increment(workout.walkSteps),
      'runDistance': FieldValue.increment(workout.runDistance),
      'overallScore': FieldValue.increment(overallScore),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // 주간 랭킹
    final weekKey = _getWeekKey(date);
    final weeklyRef = _firestore
      .collection('rankings')
      .doc('weekly')
      .collection(weekKey)
      .doc(userId);
    
    batch.set(weeklyRef, {
      'squatCount': FieldValue.increment(workout.squatCount),
      'lungeCount': FieldValue.increment(workout.lungeCount),
      'walkSteps': FieldValue.increment(workout.walkSteps),
      'runDistance': FieldValue.increment(workout.runDistance),
      'overallScore': FieldValue.increment(overallScore),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // 월간 랭킹
    final monthKey = _formatDate(date, 'YYYY-MM');
    final monthlyRef = _firestore
      .collection('rankings')
      .doc('monthly')
      .collection(monthKey)
      .doc(userId);
    
    batch.set(monthlyRef, {
      'squatCount': FieldValue.increment(workout.squatCount),
      'lungeCount': FieldValue.increment(workout.lungeCount),
      'walkSteps': FieldValue.increment(workout.walkSteps),
      'runDistance': FieldValue.increment(workout.runDistance),
      'overallScore': FieldValue.increment(overallScore),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // 전체 랭킹
    final allTimeRef = _firestore
      .collection('rankings')
      .doc('allTime')
      .collection('users')
      .doc(userId);
    
    batch.set(allTimeRef, {
      'squatCount': FieldValue.increment(workout.squatCount),
      'lungeCount': FieldValue.increment(workout.lungeCount),
      'walkSteps': FieldValue.increment(workout.walkSteps),
      'runDistance': FieldValue.increment(workout.runDistance),
      'overallScore': FieldValue.increment(overallScore),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  double _calculateOverallScore(WorkoutModel workout) {
    return workout.squatCount * 1.2 +
           workout.lungeCount * 1.2 +
           workout.walkSteps * 0.01 +
           workout.runDistance * 150;
  }
  
  String _formatDate(DateTime date, String format) {
    if (format == 'YYYY-MM-DD') {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else if (format == 'YYYY-MM') {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }
    return '';
  }
  
  String _getWeekKey(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekNum = ((date.difference(DateTime(date.year, 1, 1)).inDays + 1) / 7).ceil();
    return '${weekStart.year}-W${weekNum.toString().padLeft(2, '0')}';
  }
}
```

**장점**:
- ✅ Functions 불필요
- ✅ 한 번의 네트워크 왕복
- ✅ 즉시 반영
- ✅ 오프라인 저장도 가능 (Firestore 오프라인 캐시 활용)

**단점**:
- ⚠️ WorkoutRepository 코드가 길어짐
- ⚠️ 클라이언트 오류 시 rankings 누락 가능

---

## 🎯 최종 추천

### 현재 상황 (추정)
- 사용자: < 500명 (초기 단계)
- DAU: < 100명

### 추천 방안: 3단계 전략

#### Phase 1: 현재 방식 유지 (지금)
```dart
// workouts에서 실시간 집계
// rankings DB 없음
// 비용: 무료 범위 내
```

**조건**: 사용자 < 100명, DAU < 50명

#### Phase 2: Flutter에서 직접 rankings 업데이트 (사용자 100명 돌파 시)
```dart
// workouts + rankings 동시 저장
// Functions 불필요
// 비용: $5/월 이하
```

**조건**: 사용자 100-1,000명

#### Phase 3: Cloud Functions (필요 시)
```dart
// Functions로 자동 집계
// 클라이언트 코드 간단
// 비용: $10/월 이하
```

**조건**: 사용자 > 1,000명, 또는 여러 플랫폼 지원

---

## 💰 비용 비교 (DAU 100명 기준)

### 방법 A: 현재 방식 (workouts에서 집계)
```
Firestore 읽기:
- 100명 × 10회 × 1,000 workouts = 1,000,000 reads/day
- 월간: 30,000,000 reads
- 비용: $1.80/월
```

### 방법 B: Flutter에서 rankings 직접 업데이트
```
Firestore 읽기:
- 100명 × 10회 × 100 rankings = 100,000 reads/day
- 월간: 3,000,000 reads
- 비용: $0.18/월 (읽기)

Firestore 쓰기:
- 100명 × 5회 workout × 4 periods = 2,000 writes/day
- 월간: 60,000 writes
- 비용: $0.11/월 (쓰기)

총: $0.29/월
```

### 방법 C: Cloud Functions
```
방법 B + Functions 비용: $5/월
총: $5.29/월
```

**결론**: DAU 100명이면 **방법 A (현재 방식)로도 충분!**

---

## 🔍 실제 측정해보기

현재 앱에서 실제 사용자 수와 조회 패턴을 측정:

```dart
// Firebase Console → Firestore → Usage 탭
// 확인 사항:
// 1. 일일 읽기 횟수
// 2. 일일 쓰기 횟수
// 3. 무료 할당량 대비 사용량
```

**판단 기준**:
- 읽기 < 50,000/day → 현재 방식 유지
- 읽기 > 50,000/day → rankings 방식으로 전환
- 읽기 > 500,000/day → Cloud Functions 고려

---

## 🎯 결론

### 당신의 질문에 대한 답변

1. **"Functions를 써야하는건가?"**
   → **아니요!** Flutter에서 직접 rankings에 쓰면 됩니다. 더 간단합니다.

2. **"rankings DB가 더 효율적인 거 맞아?"**
   → **사용자 수에 따라 다릅니다!**
   - 사용자 < 100명: 현재 방식도 OK (무료 범위)
   - 사용자 100-1,000명: rankings 방식 추천 (비용 90% 절감)
   - 사용자 > 1,000명: rankings 방식 필수 (비용 95% 절감)

### 최종 추천

**지금 당장은**: 현재 방식 유지
- 이유: 초기 단계, 사용자 적음, 무료 범위 내

**사용자 100명 돌파 시**: Flutter에서 rankings 직접 업데이트
- 이유: Functions 없이도 충분, 간단한 코드

**사용자 1,000명 돌파 시**: 필요하면 Cloud Functions 고려
- 이유: 안정성, 일관성, 여러 플랫폼 지원

---

## 📊 의사결정 플로우차트

```
[현재 Firebase Usage 확인]
    ↓
[읽기 < 50,000/day?]
    ↓ Yes
[현재 방식 유지] ✅
    ↓ No
[읽기 < 500,000/day?]
    ↓ Yes
[Flutter에서 rankings 직접 업데이트] ✅
    ↓ No
[Cloud Functions 도입] ✅
```

**핵심**: 필요할 때까지 기다리세요! 최적화는 문제가 생긴 후에 해도 늦지 않습니다. 🎯
