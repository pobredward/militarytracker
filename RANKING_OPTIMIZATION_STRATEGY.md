# 랭킹 시스템 최적화 전략

## 🔴 현재 구조의 문제점

### 1. **과도한 Firestore 읽기**

#### 현재 방식
```dart
// 사용자가 탭 전환할 때마다 전체 계산
getRankings(period: daily, category: squats)    // 읽기: N개 workout + M개 user
getRankings(period: weekly, category: squats)   // 읽기: N개 workout + M개 user
getRankings(period: monthly, category: squats)  // 읽기: N개 workout + M개 user
...
```

**문제**:
- 4개 기간 × 5개 카테고리 = **20개 조합**
- 사용자가 탭을 바꿀 때마다 **전체 workouts 컬렉션 스캔**
- 사용자 100명이라면: **100회 workout 읽기 + 100회 user 읽기** (탭 전환마다!)

#### 실제 비용 예시
```
일간 랭킹 조회:
- workouts 읽기: 100개 (오늘 운동한 사용자들)
- users 읽기: 50개 (운동 기록이 있는 사용자)
= 150 reads

주간 랭킹 조회:
- workouts 읽기: 500개 (이번 주 운동 기록)
- users 읽기: 80개
= 580 reads

월간 랭킹 조회:
- workouts 읽기: 2000개 (이번 달 운동 기록)
- users 읽기: 100개
= 2100 reads

전체 랭킹 조회:
- workouts 읽기: 10000개 (전체 기간)
- users 읽기: 200개
= 10200 reads

총계: 13,030 reads (단 4번 탭 전환으로!)
```

### 2. **실시간 계산의 비효율**

```dart
// 매번 실시간으로 집계
for (final workoutDoc in workoutsSnapshot.docs) {
  // 모든 운동 데이터를 순회하며 합산
  userStats[userId]!['squats'] = ...
}
```

**문제**:
- 클라이언트 측에서 무거운 계산
- 같은 계산을 여러 사용자가 중복 수행
- 데이터가 많아질수록 점점 느려짐

### 3. **캐싱 부재**

```dart
final rankingListProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) async {
  // autoDispose로 인해 화면 나갔다 오면 다시 fetch
  return repository.getRankings(...);
});
```

**문제**:
- `autoDispose`로 인해 화면 전환 시 캐시 날아감
- 동일한 데이터를 반복 조회

---

## 🟢 최적화 전략

### 전략 A: **사전 집계 컬렉션 (Pre-aggregated Collection)** ⭐️ 추천

#### 구조

```
rankings/
  {userId}/
    daily/
      {YYYY-MM-DD}/
        - squatCount: 50
        - lungeCount: 30
        - walkSteps: 5000
        - runDistance: 3.5
        - overallScore: 250.5
        - timestamp: ...
    weekly/
      {YYYY-Wnn}/  (예: 2024-W01)
        - squatCount: 350
        - lungeCount: 210
        - ...
    monthly/
      {YYYY-MM}/
        - squatCount: 1500
        - ...
    allTime/
      stats/
        - squatCount: 10000
        - ...
```

#### 장점
✅ **읽기 최적화**: 기간별로 이미 집계된 데이터만 읽음
✅ **인덱싱 용이**: 각 필드에 인덱스 생성 가능
✅ **쿼리 간단**: 정렬만 하면 됨
✅ **확장 가능**: 사용자 수가 늘어도 성능 일정

#### 구현

##### 1. 데이터 쓰기 (Cloud Functions 사용)

```typescript
// Firebase Cloud Functions
exports.onWorkoutCreated = functions.firestore
  .document('workouts/{workoutId}')
  .onCreate(async (snap, context) => {
    const workout = snap.data();
    const userId = workout.userId;
    const date = workout.date.toDate();
    
    const batch = admin.firestore().batch();
    
    // 일간 집계
    const dailyKey = format(date, 'yyyy-MM-dd');
    const dailyRef = db.collection('rankings')
      .doc(userId)
      .collection('daily')
      .doc(dailyKey);
    
    batch.set(dailyRef, {
      squatCount: admin.firestore.FieldValue.increment(workout.squatCount),
      lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount),
      walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps),
      runDistance: admin.firestore.FieldValue.increment(workout.runDistance),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    
    // 주간 집계
    const weekKey = format(date, 'yyyy-\'W\'II'); // 2024-W01
    const weeklyRef = db.collection('rankings')
      .doc(userId)
      .collection('weekly')
      .doc(weekKey);
    
    batch.set(weeklyRef, {
      squatCount: admin.firestore.FieldValue.increment(workout.squatCount),
      // ... 동일
    }, { merge: true });
    
    // 월간 집계
    const monthKey = format(date, 'yyyy-MM');
    const monthlyRef = db.collection('rankings')
      .doc(userId)
      .collection('monthly')
      .doc(monthKey);
    
    batch.set(monthlyRef, { /* ... */ }, { merge: true });
    
    // 전체 집계
    const allTimeRef = db.collection('rankings')
      .doc(userId)
      .collection('allTime')
      .doc('stats');
    
    batch.set(allTimeRef, { /* ... */ }, { merge: true });
    
    // 종합 점수 계산 후 저장
    await batch.commit();
  });
```

##### 2. 데이터 읽기 (Flutter)

```dart
class RankingRepository {
  Future<List<RankingModel>> getRankings({
    required RankingPeriod period,
    required RankingCategory category,
    int limit = 100,
  }) async {
    final periodKey = _getPeriodKey(period); // "2024-01-15", "2024-W01", etc.
    
    // 1단계: 해당 기간의 집계 데이터만 조회 (엄청나게 빠름!)
    final snapshot = await _firestore
      .collectionGroup(period.collectionName) // 'daily', 'weekly', etc.
      .where(FieldPath.documentId, isEqualTo: periodKey)
      .orderBy(_getCategoryField(category), descending: true)
      .limit(limit)
      .get();
    
    // 2단계: 부모 userId 추출 및 사용자 정보 조회
    final rankings = <RankingModel>[];
    
    for (final doc in snapshot.docs) {
      final userId = doc.reference.parent.parent!.id;
      final data = doc.data();
      
      rankings.add(RankingModel(
        userId: userId,
        squatCount: data['squatCount'] ?? 0,
        lungeCount: data['lungeCount'] ?? 0,
        walkSteps: data['walkSteps'] ?? 0,
        runDistance: data['runDistance'] ?? 0.0,
        // ...
      ));
    }
    
    // 3단계: 사용자 정보 배치 조회 (10개씩)
    await _enrichWithUserInfo(rankings);
    
    return rankings;
  }
}
```

#### 비용 비교

**Before (현재 방식)**:
```
일간 스쿼트 랭킹: 100 workouts + 50 users = 150 reads
주간 스쿼트 랭킹: 500 workouts + 80 users = 580 reads
월간 스쿼트 랭킹: 2000 workouts + 100 users = 2100 reads
전체 스쿼트 랭킹: 10000 workouts + 200 users = 10200 reads
---
총계: 13,030 reads
```

**After (사전 집계)**:
```
일간 스쿼트 랭킹: 100 daily docs + 50 users = 150 reads
주간 스쿼트 랭킹: 100 weekly docs + 50 users = 150 reads
월간 스쿼트 랭킹: 100 monthly docs + 50 users = 150 reads
전체 스쿼트 랭킹: 100 allTime docs + 50 users = 150 reads
---
총계: 600 reads (95% 감소! 🎉)
```

---

### 전략 B: **복합 인덱스 + 캐싱**

현재 구조를 유지하되 최적화만 적용

#### 1. Firestore 복합 인덱스 생성

```
workouts 컬렉션:
- 인덱스 1: (date ASC, userId ASC)
- 인덱스 2: (date DESC, squatCount DESC)
- 인덱스 3: (date DESC, lungeCount DESC)
...
```

#### 2. 캐싱 레이어 추가

```dart
// 캐시 관리자
class RankingCacheManager {
  static final _cache = <String, CachedRanking>{};
  static const _cacheDuration = Duration(minutes: 5);
  
  static String _getCacheKey(RankingPeriod period, RankingCategory category) {
    return '${period.name}_${category.name}';
  }
  
  static List<RankingModel>? get(RankingPeriod period, RankingCategory category) {
    final key = _getCacheKey(period, category);
    final cached = _cache[key];
    
    if (cached == null) return null;
    
    // 캐시 만료 체크
    if (DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _cache.remove(key);
      return null;
    }
    
    return cached.data;
  }
  
  static void set(
    RankingPeriod period,
    RankingCategory category,
    List<RankingModel> data,
  ) {
    final key = _getCacheKey(period, category);
    _cache[key] = CachedRanking(
      data: data,
      timestamp: DateTime.now(),
    );
  }
  
  static void invalidate() {
    _cache.clear();
  }
}

class CachedRanking {
  final List<RankingModel> data;
  final DateTime timestamp;
  
  CachedRanking({required this.data, required this.timestamp});
}

// Provider에서 사용
final rankingListProvider = FutureProvider.family<List<RankingModel>, RankingQuery>(
  (ref, query) async {
    // 1. 캐시 확인
    final cached = RankingCacheManager.get(query.period, query.category);
    if (cached != null) {
      return cached;
    }
    
    // 2. Firestore에서 조회
    final repository = ref.read(rankingRepositoryProvider);
    final data = await repository.getRankings(
      period: query.period,
      category: query.category,
    );
    
    // 3. 캐시에 저장
    RankingCacheManager.set(query.period, query.category, data);
    
    return data;
  },
);
```

#### 3. 쿼리 최적화

```dart
Future<List<RankingModel>> getRankings({
  required RankingPeriod period,
  required RankingCategory category,
  int limit = 100,
}) async {
  // 특정 카테고리에 집중된 쿼리로 변경
  Query query = _firestore.collection('workouts');
  
  // 날짜 범위 필터
  final dateRange = _getDateRangeForPeriod(period);
  if (dateRange != null) {
    query = query
      .where('date', isGreaterThanOrEqualTo: dateRange['start'])
      .where('date', isLessThanOrEqualTo: dateRange['end']);
  }
  
  // 카테고리별 필터 추가 (0보다 큰 값만)
  final categoryField = _getCategoryField(category);
  if (categoryField != null) {
    query = query.where(categoryField, isGreaterThan: 0);
  }
  
  // 정렬 (인덱스 활용)
  query = query.orderBy(categoryField, descending: true);
  
  final snapshot = await query.limit(limit * 7).get(); // 일주일치 최대
  
  // 나머지 집계 로직...
}
```

#### 비용 비교

**Before**:
```
랭킹 조회: 2000 reads
```

**After**:
```
첫 조회: 2000 reads
캐시된 조회 (5분 내): 0 reads
---
평균: ~400 reads (80% 감소)
```

---

### 전략 C: **하이브리드 (추천!)** ⭐️⭐️⭐️

전략 A + 전략 B의 조합

#### 구조

```
1. 실시간 집계 (Cloud Functions)
   - workout 생성 시 rankings 컬렉션 업데이트
   
2. 캐싱 레이어
   - 클라이언트 측 5분 캐시
   
3. 점진적 로딩
   - 먼저 캐시 표시
   - 백그라운드에서 최신 데이터 fetch
```

#### 구현

```dart
final rankingListProvider = StreamProvider.autoDispose<List<RankingModel>>((ref) {
  final period = ref.watch(selectedRankingPeriodProvider);
  final category = ref.watch(selectedRankingCategoryProvider);
  
  // 1. 캐시 먼저 반환
  final cached = RankingCacheManager.get(period, category);
  if (cached != null) {
    // 캐시를 즉시 emit
    return Stream.value(cached);
  }
  
  // 2. Firestore에서 실시간 스트림
  final periodKey = _getPeriodKey(period);
  
  return _firestore
    .collectionGroup(period.collectionName)
    .where(FieldPath.documentId, isEqualTo: periodKey)
    .orderBy(_getCategoryField(category), descending: true)
    .limit(100)
    .snapshots()
    .asyncMap((snapshot) async {
      final rankings = await _processSnapshot(snapshot);
      
      // 캐시 업데이트
      RankingCacheManager.set(period, category, rankings);
      
      return rankings;
    });
});
```

---

## 📊 전략 비교표

| 전략 | Firestore 읽기 | 구현 복잡도 | 실시간성 | 확장성 | 권장도 |
|------|---------------|------------|---------|--------|--------|
| **현재** | 10,000+ | 낮음 | 완벽 | 낮음 | ❌ |
| **A (사전 집계)** | 150 | 높음 (CF 필요) | 높음 | 매우 높음 | ⭐️⭐️⭐️⭐️ |
| **B (캐싱)** | 400 | 중간 | 중간 | 중간 | ⭐️⭐️⭐️ |
| **C (하이브리드)** | 150 | 높음 | 매우 높음 | 매우 높음 | ⭐️⭐️⭐️⭐️⭐️ |

---

## 🚀 추천 구현 단계

### Phase 1: 즉시 개선 (1-2일)

1. **캐싱 레이어 추가**
   ```dart
   - RankingCacheManager 구현
   - Provider에 캐싱 로직 통합
   - autoDispose 제거 (keepAlive 사용)
   ```

2. **쿼리 최적화**
   ```dart
   - 불필요한 where 절 제거
   - limit 적용
   - 카테고리별 필드 인덱싱
   ```

**예상 효과**: 읽기 80% 감소

### Phase 2: 중기 개선 (1주일)

1. **Firebase Cloud Functions 구축**
   ```typescript
   - onWorkoutCreated trigger
   - onWorkoutUpdated trigger
   - 집계 컬렉션 생성
   ```

2. **Firestore 구조 변경**
   ```
   - rankings 컬렉션 생성
   - 마이그레이션 스크립트 작성
   ```

3. **Flutter 코드 리팩토링**
   ```dart
   - Repository 메서드 변경
   - Provider 업데이트
   ```

**예상 효과**: 읽기 95% 감소

### Phase 3: 장기 개선 (2주일)

1. **실시간 스트림 구현**
   ```dart
   - StreamProvider 전환
   - 실시간 업데이트 UI
   ```

2. **오프라인 지원**
   ```dart
   - Firestore 오프라인 캐시
   - 로컬 DB (Hive/Isar)
   ```

3. **성능 모니터링**
   ```dart
   - Firebase Performance Monitoring
   - 쿼리 분석 대시보드
   ```

---

## 💰 비용 절감 계산

### 현재 구조

```
DAU (Daily Active Users): 1,000명
평균 랭킹 조회 횟수: 10회/일/사용자

총 reads = 1,000 × 10 × 2,000 = 20,000,000 reads/day
월간 reads = 20M × 30 = 600,000,000 reads
```

**Firestore 비용**:
- 무료 할당량: 50,000 reads/day
- 초과분: 600M - 1.5M = 598.5M reads
- 비용: $0.06 per 100,000 reads
- **월 비용: $359**

### 최적화 후 (전략 C)

```
총 reads = 1,000 × 10 × 150 = 1,500,000 reads/day
월간 reads = 1.5M × 30 = 45,000,000 reads
```

**Firestore 비용**:
- 무료 할당량: 50,000 reads/day
- 초과분: 45M - 1.5M = 43.5M reads
- 비용: $0.06 per 100,000 reads
- **월 비용: $26**

**절감액: $333/월 (93% 절감)** 🎉

---

## 🔧 구현 예시

### 1. Cloud Functions (TypeScript)

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { format, startOfWeek, startOfMonth } from 'date-fns';

admin.initializeApp();
const db = admin.firestore();

export const onWorkoutCreated = functions.firestore
  .document('workouts/{workoutId}')
  .onCreate(async (snap, context) => {
    const workout = snap.data();
    const userId = workout.userId;
    const date = workout.date.toDate();
    
    const updates: any[] = [];
    
    // 일간 집계
    const dailyKey = format(date, 'yyyy-MM-dd');
    updates.push(updateRankingPeriod(userId, 'daily', dailyKey, workout));
    
    // 주간 집계
    const weekStart = startOfWeek(date, { weekStartsOn: 1 }); // 월요일 시작
    const weekKey = format(weekStart, 'yyyy-MM-dd');
    updates.push(updateRankingPeriod(userId, 'weekly', weekKey, workout));
    
    // 월간 집계
    const monthStart = startOfMonth(date);
    const monthKey = format(monthStart, 'yyyy-MM-dd');
    updates.push(updateRankingPeriod(userId, 'monthly', monthKey, workout));
    
    // 전체 집계
    updates.push(updateRankingPeriod(userId, 'allTime', 'stats', workout));
    
    await Promise.all(updates);
  });

async function updateRankingPeriod(
  userId: string,
  period: string,
  key: string,
  workout: any
) {
  const ref = db
    .collection('rankings')
    .doc(userId)
    .collection(period)
    .doc(key);
  
  const overallScore = calculateOverallScore(workout);
  
  await ref.set({
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

function calculateOverallScore(workout: any): number {
  const squatScore = (workout.squatCount || 0) * 1.2;
  const lungeScore = (workout.lungeCount || 0) * 1.2;
  const walkScore = (workout.walkSteps || 0) * 0.01;
  const runScore = (workout.runDistance || 0) * 150;
  
  return squatScore + lungeScore + walkScore + runScore;
}
```

### 2. Flutter Repository (최적화)

```dart
class RankingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 사전 집계된 랭킹 데이터 조회
  Future<List<RankingModel>> getRankingsOptimized({
    required RankingPeriod period,
    required RankingCategory category,
    int limit = 100,
  }) async {
    try {
      final periodKey = _getPeriodKey(period);
      final sortField = _getCategoryField(category);
      
      // 1단계: collectionGroup으로 모든 사용자의 해당 기간 데이터 조회
      final snapshot = await _firestore
        .collectionGroup(_getPeriodCollectionName(period))
        .where(FieldPath.documentId, isEqualTo: periodKey)
        .orderBy(sortField, descending: true)
        .limit(limit)
        .get();
      
      // 2단계: 사용자 ID 추출
      final userIds = snapshot.docs
        .map((doc) => doc.reference.parent.parent!.id)
        .toList();
      
      if (userIds.isEmpty) return [];
      
      // 3단계: 사용자 정보 배치 조회
      final rankings = <RankingModel>[];
      
      for (int i = 0; i < userIds.length; i += 10) {
        final batchIds = userIds.skip(i).take(10).toList();
        final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();
        
        final userMap = Map.fromEntries(
          usersSnapshot.docs.map((doc) => MapEntry(doc.id, doc.data()))
        );
        
        // 4단계: RankingModel 생성
        for (int j = 0; j < batchIds.length; j++) {
          final userId = batchIds[j];
          final statsDoc = snapshot.docs[i + j];
          final stats = statsDoc.data();
          final userData = userMap[userId] ?? {};
          
          rankings.add(RankingModel(
            userId: userId,
            displayName: userData['displayName'] ?? '사용자',
            photoUrl: userData['photoUrl'],
            squatCount: stats['squatCount'] ?? 0,
            lungeCount: stats['lungeCount'] ?? 0,
            walkSteps: stats['walkSteps'] ?? 0,
            runDistance: stats['runDistance'] ?? 0.0,
            overallScore: stats['overallScore'] ?? 0.0,
            rank: j + 1 + i,
            period: period,
            category: category,
            lastUpdated: (stats['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }
      
      return rankings;
    } catch (e, stackTrace) {
      debugPrint('랭킹 조회 실패: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
  
  String _getPeriodKey(RankingPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriod.daily:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      case RankingPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      
      case RankingPeriod.monthly:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      
      case RankingPeriod.allTime:
        return 'stats';
    }
  }
  
  String _getPeriodCollectionName(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
        return 'daily';
      case RankingPeriod.weekly:
        return 'weekly';
      case RankingPeriod.monthly:
        return 'monthly';
      case RankingPeriod.allTime:
        return 'allTime';
    }
  }
  
  String _getCategoryField(RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return 'overallScore';
      case RankingCategory.squats:
        return 'squatCount';
      case RankingCategory.lunges:
        return 'lungeCount';
      case RankingCategory.walking:
        return 'walkSteps';
      case RankingCategory.running:
        return 'runDistance';
    }
  }
}
```

### 3. 캐싱 레이어

```dart
class RankingCacheManager {
  static final Map<String, _CachedRanking> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  static String _key(RankingPeriod period, RankingCategory category) =>
      '${period.name}_${category.name}';
  
  static List<RankingModel>? get(
    RankingPeriod period,
    RankingCategory category,
  ) {
    final cached = _cache[_key(period, category)];
    
    if (cached == null) return null;
    
    if (DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      _cache.remove(_key(period, category));
      return null;
    }
    
    return cached.data;
  }
  
  static void set(
    RankingPeriod period,
    RankingCategory category,
    List<RankingModel> data,
  ) {
    _cache[_key(period, category)] = _CachedRanking(
      data: data,
      timestamp: DateTime.now(),
    );
  }
  
  static void clear() => _cache.clear();
}

class _CachedRanking {
  final List<RankingModel> data;
  final DateTime timestamp;
  
  _CachedRanking({required this.data, required this.timestamp});
}
```

### 4. Provider 업데이트

```dart
final rankingListProvider = FutureProvider.autoDispose
  .family<List<RankingModel>, _RankingQuery>((ref, query) async {
  
  // 1. 캐시 확인
  final cached = RankingCacheManager.get(query.period, query.category);
  if (cached != null) {
    return cached;
  }
  
  // 2. Firestore 조회
  final repository = ref.read(rankingRepositoryProvider);
  final rankings = await repository.getRankingsOptimized(
    period: query.period,
    category: query.category,
    limit: 100,
  );
  
  // 3. 캐시 저장
  RankingCacheManager.set(query.period, query.category, rankings);
  
  return rankings;
});

// Helper class
class _RankingQuery {
  final RankingPeriod period;
  final RankingCategory category;
  
  _RankingQuery(this.period, this.category);
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is _RankingQuery &&
    period == other.period &&
    category == other.category;
  
  @override
  int get hashCode => Object.hash(period, category);
}
```

---

## 📋 마이그레이션 체크리스트

### Cloud Functions 배포

- [ ] Firebase CLI 설치
- [ ] Functions 프로젝트 초기화
- [ ] `onWorkoutCreated` 함수 작성
- [ ] `onWorkoutUpdated` 함수 작성
- [ ] 테스트 환경에서 검증
- [ ] 프로덕션 배포

### Firestore 구조 변경

- [ ] `rankings` 컬렉션 생성
- [ ] 기존 데이터 마이그레이션 스크립트 작성
- [ ] 마이그레이션 실행
- [ ] 데이터 검증

### Flutter 코드 업데이트

- [ ] `RankingRepository` 리팩토링
- [ ] `RankingCacheManager` 구현
- [ ] Provider 업데이트
- [ ] UI 테스트
- [ ] 성능 측정

### 모니터링

- [ ] Firebase Performance Monitoring 설정
- [ ] 쿼리 분석 대시보드 구축
- [ ] 비용 알림 설정

---

## 🎯 결론

**추천 방안**: **전략 C (하이브리드)** ⭐️⭐️⭐️⭐️⭐️

**이유**:
1. ✅ **최대 성능**: Firestore 읽기 95% 감소
2. ✅ **실시간성**: 데이터 즉시 반영
3. ✅ **확장성**: 사용자 수 증가에도 성능 유지
4. ✅ **비용 효율**: 월 $333 절감
5. ✅ **사용자 경험**: 빠른 로딩, 부드러운 UX

**구현 우선순위**:
1. Phase 1: 캐싱 (1-2일) → 즉각적인 개선
2. Phase 2: Cloud Functions (1주일) → 근본적인 최적화
3. Phase 3: 실시간 스트림 (2주일) → UX 개선
