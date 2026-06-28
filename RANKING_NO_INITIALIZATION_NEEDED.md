# 랭킹 시스템 - 초기화 불필요한 설계

## 🔴 문제: users 컬렉션 current* 필드의 한계

### 초기화가 필요한 설계 (비추천)

```
users/{userId}/
  - currentDailySquats: 50      ← 매일 자정 0으로 초기화 필요!
  - currentWeeklySquats: 350    ← 매주 월요일 0으로 초기화 필요!
  - currentMonthlySquats: 1500  ← 매달 1일 0으로 초기화 필요!
  - lastDailyUpdate: "2024-01-15"
```

**문제점**:
1. Cloud Scheduler로 모든 users 초기화 → 1,000명이면 1,000 writes/일
2. 클라이언트에서 체크 → 앱 안 켜면 누락
3. 타임존 문제 → 사용자마다 다른 자정

**비용**:
- 1,000명 × 30일 = 30,000 writes/월 → $0.54/월
- Cloud Scheduler 실행 비용 → $0.10/월
- **총 $0.64/월 (쓸데없는 비용!)**

---

## 🟢 해결책 1: rankings 컬렉션 (원래 제안)

### 구조

```
rankings/
  daily/
    2024-01-15/
      {userId}/
        - squatCount: 50
        - overallScore: 100
  weekly/
    2024-W03/
      {userId}/...
  monthly/
    2024-01/
      {userId}/...
```

### 초기화 불필요!

```dart
// 오늘 랭킹 조회
final today = '2024-01-15';
_firestore
  .collection('rankings')
  .doc('daily')
  .collection(today)  ← 문서가 있으면 있는 것, 없으면 0
  .orderBy('squatCount', desc)
  .limit(100)
  .get();

// 내일 랭킹 조회
final tomorrow = '2024-01-16';
_firestore
  .collection('rankings')
  .doc('daily')
  .collection(tomorrow)  ← 자동으로 새 날짜!
  .orderBy('squatCount', desc)
  .limit(100)
  .get();
```

**장점**:
- ✅ 초기화 불필요 (날짜별 컬렉션 분리)
- ✅ 과거 데이터 자동 보관
- ✅ 타임존 문제 없음 (서버 시간 기준)

---

## 🟢 해결책 2: users 컬렉션에 타임스탬프 저장

### 구조

```
users/{userId}/
  - todaySquats: 50
  - todayDate: "2024-01-15"      ← 날짜 저장!
  
  - weekSquats: 350
  - weekStart: "2024-01-08"      ← 주 시작일 저장!
  
  - monthSquats: 1500
  - monthStart: "2024-01-01"     ← 월 시작일 저장!
  
  - allTimeSquats: 10000         ← 초기화 불필요
```

### 운동 완료 시 로직

```dart
Future<void> updateUserStats(String userId, WorkoutModel workout) async {
  final userRef = _firestore.collection('users').doc(userId);
  final userData = (await userRef.get()).data()!;
  
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  
  Map<String, dynamic> updates = {};
  
  // 1. 일간 체크
  if (userData['todayDate'] != today) {
    // 새로운 날 → 초기화
    updates['todaySquats'] = workout.squatCount;
    updates['todayDate'] = today;
  } else {
    // 같은 날 → 증가
    updates['todaySquats'] = FieldValue.increment(workout.squatCount);
  }
  
  // 2. 주간 체크
  final weekStart = _getWeekStart(now);
  if (userData['weekStart'] != weekStart) {
    updates['weekSquats'] = workout.squatCount;
    updates['weekStart'] = weekStart;
  } else {
    updates['weekSquats'] = FieldValue.increment(workout.squatCount);
  }
  
  // 3. 월간 체크
  final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  if (userData['monthStart'] != monthStart) {
    updates['monthSquats'] = workout.squatCount;
    updates['monthStart'] = monthStart;
  } else {
    updates['monthSquats'] = FieldValue.increment(workout.squatCount);
  }
  
  // 4. 전체 (항상 증가)
  updates['allTimeSquats'] = FieldValue.increment(workout.squatCount);
  
  await userRef.update(updates);
}

String _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  final monday = date.subtract(Duration(days: weekday - 1));
  return DateFormat('yyyy-MM-dd').format(monday);
}
```

### 랭킹 조회

```dart
// 오늘 랭킹
_firestore
  .collection('users')
  .where('todayDate', isEqualTo: '2024-01-15')  ← 오늘인 사람만
  .orderBy('todaySquats', descending: true)
  .limit(100)
  .get();
```

**문제**: 
- ❌ 복합 인덱스 필요: `(todayDate, todaySquats)`
- ❌ 매일 새로운 날짜 → 인덱스 효율 떨어짐
- ❌ "오늘 운동 안 한 사람" 제외됨

---

## 🟢 해결책 3: 하이브리드 + 지연 초기화

### 구조

```
users/{userId}/
  - dailySquats_20240115: 50    ← 날짜를 필드명에 포함!
  - weeklySquats_2024W03: 350
  - monthlySquats_202401: 1500
  - allTimeSquats: 10000
```

### 운동 완료 시

```dart
Future<void> updateUserStats(String userId, WorkoutModel workout) async {
  final now = DateTime.now();
  final dailyKey = 'dailySquats_${_formatDate(now, "yyyyMMdd")}';
  final weeklyKey = 'weeklySquats_${_getWeekKey(now)}';
  final monthlyKey = 'monthlySquats_${_formatDate(now, "yyyyMM")}';
  
  await _firestore.collection('users').doc(userId).set({
    dailyKey: FieldValue.increment(workout.squatCount),
    weeklyKey: FieldValue.increment(workout.squatCount),
    monthlyKey: FieldValue.increment(workout.squatCount),
    'allTimeSquats': FieldValue.increment(workout.squatCount),
  }, SetOptions(merge: true));
}
```

**장점**:
- ✅ 초기화 불필요!
- ✅ 자동으로 새 필드 생성
- ✅ 과거 데이터 보관

**문제**:
- ❌ 필드명 동적 → 쿼리 복잡
- ❌ 인덱스 매일/매주/매달 증가

---

## 🏆 최종 추천: rankings 컬렉션 (원래 방식)

### 왜?

| 기준 | rankings | users (current*) | users (동적 필드) |
|------|----------|------------------|-------------------|
| 초기화 | 불필요 ✅ | 필요 ❌ | 불필요 ✅ |
| 인덱스 | 5개 고정 ✅ | 5개 고정 ✅ | 매일 증가 ❌ |
| 과거 데이터 | 자동 보관 ✅ | 별도 저장 필요 ❌ | 보관됨 ✅ |
| 쿼리 복잡도 | 낮음 ✅ | 낮음 ✅ | 높음 ❌ |
| 코드 복잡도 | 중간 | 높음 (초기화 로직) | 낮음 |

---

## 💻 최종 구현: rankings 컬렉션 (Flutter에서 직접)

### WorkoutRepository 수정

```dart
class WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<String?> createWorkout(WorkoutModel workout) async {
    try {
      final batch = _firestore.batch();
      
      // 1. workouts 저장
      final workoutRef = _firestore.collection('workouts').doc();
      batch.set(workoutRef, workout.toJson());
      
      // 2. rankings 업데이트 (초기화 불필요!)
      await _updateRankings(batch, workout);
      
      // 3. 커밋
      await batch.commit();
      
      return workoutRef.id;
    } catch (e) {
      logger.e('Error creating workout: $e');
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
    
    final overallScore = _calculateOverallScore(workout);
    
    // 일간 랭킹 (날짜별 컬렉션)
    final dailyKey = DateFormat('yyyy-MM-dd').format(date);
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
    final monthKey = DateFormat('yyyy-MM').format(date);
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
  
  String _getWeekKey(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }
}
```

### 랭킹 조회

```dart
class RankingRepository {
  Future<List<RankingModel>> getRankings({
    required RankingPeriod period,
    required RankingCategory category,
  }) async {
    final periodKey = _getPeriodKey(period);
    final sortField = _getCategoryField(category);
    
    final snapshot = await _firestore
      .collection('rankings')
      .doc(_getPeriodName(period))
      .collection(periodKey)  ← 날짜별 컬렉션 자동 분리!
      .orderBy(sortField, descending: true)
      .limit(100)
      .get();
    
    // RankingModel 생성...
  }
  
  String _getPeriodKey(RankingPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriod.daily:
        return DateFormat('yyyy-MM-dd').format(now);
      case RankingPeriod.weekly:
        return _getWeekKey(now);
      case RankingPeriod.monthly:
        return DateFormat('yyyy-MM').format(now);
      case RankingPeriod.allTime:
        return 'users';
    }
  }
}
```

---

## 🎯 핵심 포인트

### rankings 컬렉션의 장점

```
rankings/
  daily/
    2024-01-15/    ← 오늘
      {userId}/...
    2024-01-16/    ← 내일 (자동 생성!)
      {userId}/...
    2024-01-17/    ← 모레 (자동 생성!)
      {userId}/...
```

**초기화가 필요 없는 이유**:
1. 날짜별로 **별도 컬렉션**
2. 새로운 날 → 새로운 컬렉션 **자동 생성**
3. 과거 데이터 **자동 보관**
4. Cloud Scheduler **불필요**
5. 클라이언트 체크 **불필요**

---

## 💰 비용 비교

### users current* + Scheduler

```
초기화 쓰기: 1,000명 × 30일 = 30,000 writes
랭킹 쓰기: 1,000명 × 5회 × 4 periods = 20,000 writes
Scheduler: $0.10/월

총: $0.64/월 (초기화) + $0.36/월 (랭킹) = $1.00/월
```

### rankings 컬렉션

```
랭킹 쓰기: 1,000명 × 5회 × 4 periods = 20,000 writes
Scheduler: $0 (불필요!)

총: $0.36/월
```

**절감**: $0.64/월 (64% 절감!)

---

## 🏆 최종 결론

**rankings 컬렉션이 최선입니다!**

**이유**:
1. ✅ 초기화 불필요 (날짜별 자동 분리)
2. ✅ 과거 데이터 자동 보관
3. ✅ Cloud Scheduler 불필요
4. ✅ 코드 간단 (Flutter에서 직접)
5. ✅ 비용 절감

**구현**:
- Cloud Functions ❌ 불필요
- Flutter WorkoutRepository에서 직접 rankings 업데이트 ✅

바로 구현 코드 적용해드릴까요? 🚀
