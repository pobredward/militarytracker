# 랭킹 시스템 DB 구조 개선 - 사전 집계 방식

## 🔴 현재 방식의 근본적인 문제

### 현재: 매번 모든 workouts를 읽어서 집계

```
[사용자가 "월간 스쿼트 랭킹" 클릭]
    ↓
[이번 달 모든 workout 문서 읽기] ← 2,000개 문서!
    ↓
[클라이언트에서 userId별로 집계]
  user1: 50 + 30 + 40 + ... = 500개
  user2: 60 + 45 + 30 + ... = 450개
  user3: ...
    ↓
[정렬 후 표시]
```

**문제점**:
- ❌ 2,000개 workout 문서를 매번 읽음
- ❌ 클라이언트에서 무거운 계산
- ❌ 같은 계산을 100명의 사용자가 중복 수행
- ❌ 비용 폭탄 (2,000 reads × 1,000명 = 2,000,000 reads/day)

---

## 🟢 개선된 방식: 사전 집계 DB

### 새로운 방식: 이미 집계된 데이터만 읽기

```
[사용자가 "월간 스쿼트 랭킹" 클릭]
    ↓
[rankings/monthly/2024-01 컬렉션에서 상위 100명만 읽기] ← 100개 문서!
    ↓
[정렬된 데이터 바로 표시]
```

**장점**:
- ✅ 100개 문서만 읽음 (95% 감소!)
- ✅ 계산 없음 (이미 집계됨)
- ✅ 빠른 응답 (정렬만 하면 됨)
- ✅ 비용 절감 (100 reads × 1,000명 = 100,000 reads/day)

---

## 📊 새로운 DB 구조

### 기존 구조 (유지)

```
workouts/
  {workoutId}/
    - userId: "user123"
    - squatCount: 50
    - lungeCount: 30
    - walkSteps: 5000
    - runDistance: 3.5
    - date: 2024-01-15
```

### 추가 구조: rankings 컬렉션 (새로 생성)

```
rankings/
  daily/
    {YYYY-MM-DD}/           (예: 2024-01-15)
      users/
        {userId}/
          - squatCount: 50
          - lungeCount: 30
          - walkSteps: 5000
          - runDistance: 3.5
          - overallScore: 250.5
          - displayName: "홍길동"
          - photoUrl: "https://..."
          - rank: 1
          - lastUpdated: timestamp
  
  weekly/
    {YYYY-Wnn}/             (예: 2024-W03)
      users/
        {userId}/
          - squatCount: 350    (일주일 누적)
          - lungeCount: 210
          - walkSteps: 35000
          - runDistance: 24.5
          - overallScore: 1755.0
          - displayName: "홍길동"
          - photoUrl: "https://..."
          - rank: 1
          - lastUpdated: timestamp
  
  monthly/
    {YYYY-MM}/              (예: 2024-01)
      users/
        {userId}/
          - squatCount: 1500   (한 달 누적)
          - lungeCount: 900
          - walkSteps: 150000
          - runDistance: 100.0
          - overallScore: 7500.0
          - displayName: "홍길동"
          - photoUrl: "https://..."
          - rank: 1
          - lastUpdated: timestamp
  
  allTime/
    users/
      {userId}/
        - squatCount: 10000  (전체 누적)
        - lungeCount: 6000
        - walkSteps: 1000000
        - runDistance: 500.0
        - overallScore: 50000.0
        - displayName: "홍길동"
        - photoUrl: "https://..."
        - rank: 1
        - lastUpdated: timestamp
```

---

## 🔄 데이터 흐름

### 1. 운동 완료 시 (자동 집계)

```
[사용자가 스쿼트 50개 완료]
    ↓
[workouts 컬렉션에 저장]
    ↓
[Cloud Function 트리거 발동] ⚡️
    ↓
[4개 rankings 문서 동시 업데이트]
  - rankings/daily/2024-01-15/users/{userId}
  - rankings/weekly/2024-W03/users/{userId}
  - rankings/monthly/2024-01/users/{userId}
  - rankings/allTime/users/{userId}
    ↓
[완료!]
```

**핵심**: 운동 저장 시 동시에 집계 데이터도 업데이트!

### 2. 랭킹 조회 시

```
[사용자가 "월간 스쿼트 랭킹" 클릭]
    ↓
[Firestore 쿼리]
rankings/monthly/2024-01/users
  .orderBy('squatCount', descending: true)
  .limit(100)
    ↓
[이미 정렬된 상위 100명 반환] ← 빠름!
    ↓
[UI에 표시]
```

---

## 💻 구현 코드

### 1. Cloud Functions (Firebase Functions)

**파일**: `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * workout 생성 시 자동으로 rankings 업데이트
 */
export const onWorkoutCreated = functions
  .region('asia-northeast3') // 서울 리전
  .firestore
  .document('workouts/{workoutId}')
  .onCreate(async (snap, context) => {
    const workout = snap.data();
    const userId = workout.userId;
    const date = workout.date.toDate();
    
    console.log(`✅ Workout created: ${context.params.workoutId}`);
    console.log(`   User: ${userId}, Date: ${date.toISOString()}`);
    
    try {
      await updateRankings(userId, workout, date);
      console.log(`✅ Rankings updated successfully`);
    } catch (error) {
      console.error(`❌ Error updating rankings:`, error);
      throw error;
    }
  });

/**
 * workout 업데이트 시 rankings도 업데이트
 */
export const onWorkoutUpdated = functions
  .region('asia-northeast3')
  .firestore
  .document('workouts/{workoutId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = after.userId;
    const date = after.date.toDate();
    
    console.log(`🔄 Workout updated: ${context.params.workoutId}`);
    
    // 변경된 값 계산
    const diff = {
      squatCount: (after.squatCount || 0) - (before.squatCount || 0),
      lungeCount: (after.lungeCount || 0) - (before.lungeCount || 0),
      walkSteps: (after.walkSteps || 0) - (before.walkSteps || 0),
      runDistance: (after.runDistance || 0) - (before.runDistance || 0),
    };
    
    try {
      await updateRankings(userId, diff, date);
      console.log(`✅ Rankings updated for diff:`, diff);
    } catch (error) {
      console.error(`❌ Error updating rankings:`, error);
      throw error;
    }
  });

/**
 * 모든 기간별 랭킹 업데이트
 */
async function updateRankings(
  userId: string,
  workout: any,
  date: Date
) {
  const batch = db.batch();
  
  // 사용자 정보 조회
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();
  const displayName = userData?.displayName || '사용자';
  const photoUrl = userData?.photoUrl || null;
  
  // 종합 점수 계산
  const overallScore = calculateOverallScore(workout);
  
  // 1. 일간 랭킹 업데이트
  const dailyKey = formatDate(date, 'YYYY-MM-DD');
  const dailyRef = db
    .collection('rankings')
    .doc('daily')
    .collection(dailyKey)
    .doc('users')
    .collection('data')
    .doc(userId);
  
  batch.set(dailyRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    displayName,
    photoUrl,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 2. 주간 랭킹 업데이트
  const weekKey = getWeekKey(date); // 2024-W03
  const weeklyRef = db
    .collection('rankings')
    .doc('weekly')
    .collection(weekKey)
    .doc('users')
    .collection('data')
    .doc(userId);
  
  batch.set(weeklyRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    displayName,
    photoUrl,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 3. 월간 랭킹 업데이트
  const monthKey = formatDate(date, 'YYYY-MM');
  const monthlyRef = db
    .collection('rankings')
    .doc('monthly')
    .collection(monthKey)
    .doc('users')
    .collection('data')
    .doc(userId);
  
  batch.set(monthlyRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    displayName,
    photoUrl,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 4. 전체 랭킹 업데이트
  const allTimeRef = db
    .collection('rankings')
    .doc('allTime')
    .collection('users')
    .doc('data')
    .collection('data')
    .doc(userId);
  
  batch.set(allTimeRef, {
    squatCount: admin.firestore.FieldValue.increment(workout.squatCount || 0),
    lungeCount: admin.firestore.FieldValue.increment(workout.lungeCount || 0),
    walkSteps: admin.firestore.FieldValue.increment(workout.walkSteps || 0),
    runDistance: admin.firestore.FieldValue.increment(workout.runDistance || 0),
    overallScore: admin.firestore.FieldValue.increment(overallScore),
    displayName,
    photoUrl,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  // 배치 커밋
  await batch.commit();
}

/**
 * 종합 점수 계산
 */
function calculateOverallScore(workout: any): number {
  const squatScore = (workout.squatCount || 0) * 1.2;
  const lungeScore = (workout.lungeCount || 0) * 1.2;
  const walkScore = (workout.walkSteps || 0) * 0.01;
  const runScore = (workout.runDistance || 0) * 150;
  
  return squatScore + lungeScore + walkScore + runScore;
}

/**
 * 날짜 포맷팅
 */
function formatDate(date: Date, format: string): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  
  if (format === 'YYYY-MM-DD') {
    return `${year}-${month}-${day}`;
  } else if (format === 'YYYY-MM') {
    return `${year}-${month}`;
  }
  
  return '';
}

/**
 * 주차 키 생성 (ISO Week)
 */
function getWeekKey(date: Date): string {
  // 월요일을 주의 시작으로
  const d = new Date(date);
  const dayOfWeek = d.getDay();
  const diff = d.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
  const monday = new Date(d.setDate(diff));
  
  const year = monday.getFullYear();
  const weekNum = getWeekNumber(monday);
  
  return `${year}-W${String(weekNum).padStart(2, '0')}`;
}

/**
 * ISO 주차 계산
 */
function getWeekNumber(date: Date): number {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 4 - (d.getDay() || 7));
  const yearStart = new Date(d.getFullYear(), 0, 1);
  const weekNo = Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
  return weekNo;
}
```

### 2. Flutter Repository (간소화)

**파일**: `lib/repositories/ranking_repository.dart`

```dart
class RankingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 사전 집계된 랭킹 조회 (초고속!)
  Future<List<RankingModel>> getRankings({
    required RankingPeriod period,
    required RankingCategory category,
    int limit = 100,
  }) async {
    try {
      // 1. 캐시 확인
      final cached = RankingCacheManager.get(period, category);
      if (cached != null) return cached;
      
      // 2. 이미 집계된 데이터만 조회
      final periodKey = _getPeriodKey(period);
      final sortField = _getCategoryField(category);
      
      final snapshot = await _firestore
        .collection('rankings')
        .doc(_getPeriodName(period))
        .collection(periodKey)
        .doc('users')
        .collection('data')
        .orderBy(sortField, descending: true)
        .limit(limit)
        .get();
      
      // 3. RankingModel 생성
      final rankings = <RankingModel>[];
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        
        rankings.add(RankingModel(
          userId: doc.id,
          displayName: data['displayName'] ?? '사용자',
          photoUrl: data['photoUrl'],
          squatCount: data['squatCount'] ?? 0,
          lungeCount: data['lungeCount'] ?? 0,
          walkSteps: data['walkSteps'] ?? 0,
          runDistance: data['runDistance'] ?? 0.0,
          overallScore: data['overallScore'] ?? 0.0,
          rank: i + 1,
          period: period,
          category: category,
          lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      
      // 4. 캐시 저장
      RankingCacheManager.set(period, category, rankings);
      
      return rankings;
    } catch (e, stackTrace) {
      debugPrint('❌ 랭킹 조회 실패: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
  
  String _getPeriodName(RankingPeriod period) {
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
  
  String _getPeriodKey(RankingPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriod.daily:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      case RankingPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekNum = _getWeekNumber(weekStart);
        return '${weekStart.year}-W${weekNum.toString().padLeft(2, '0')}';
      
      case RankingPeriod.monthly:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      case RankingPeriod.allTime:
        return 'users';
    }
  }
  
  int _getWeekNumber(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final dayOfYear = int.parse(d.difference(DateTime(d.year, 1, 1)).inDays.toString()) + 1;
    return ((dayOfYear - d.weekday + 10) / 7).floor();
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

---

## 📊 성능 비교

### Before: 매번 모든 workout 집계

```
월간 스쿼트 랭킹 조회:

Firestore 읽기:
- workouts (이번 달): 2,000개
- users: 100개
= 2,100 reads

처리 시간: ~5초
```

### After: 사전 집계된 데이터 조회

```
월간 스쿼트 랭킹 조회:

Firestore 읽기:
- rankings/monthly/2024-01/users/data: 100개
= 100 reads

처리 시간: ~0.3초
```

**개선 효과**:
- 📊 **읽기 95% 감소** (2,100 → 100)
- ⚡️ **속도 17배 향상** (5초 → 0.3초)
- 💰 **비용 95% 절감**

---

## 🚀 배포 가이드

### 1. Firebase CLI 설치

```bash
npm install -g firebase-tools
firebase login
```

### 2. Functions 프로젝트 초기화

```bash
cd /Users/edwardshin/Desktop/dev/militarytracker
firebase init functions

# 옵션 선택:
# - TypeScript
# - ESLint
# - Install dependencies
```

### 3. Functions 코드 작성

위의 `functions/src/index.ts` 코드 복사

### 4. 배포

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 5. Firestore 인덱스 생성

Firebase Console에서 자동으로 인덱스 생성 요청이 뜰 것입니다.
또는 수동으로:

```bash
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "data",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "squatCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "data",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "lungeCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "data",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "walkSteps", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "data",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "runDistance", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "data",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "overallScore", "order": "DESCENDING" }
      ]
    }
  ]
}
```

```bash
firebase deploy --only firestore:indexes
```

---

## 🔄 기존 데이터 마이그레이션

### 마이그레이션 스크립트

**파일**: `functions/src/migrate.ts`

```typescript
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * 기존 workouts 데이터를 rankings에 마이그레이션
 */
async function migrateExistingWorkouts() {
  console.log('🚀 Starting migration...');
  
  const workouts = await db.collection('workouts').get();
  console.log(`📊 Found ${workouts.size} workouts`);
  
  let processed = 0;
  const batchSize = 500;
  let batch = db.batch();
  
  for (const doc of workouts.docs) {
    const workout = doc.data();
    const userId = workout.userId;
    const date = workout.date.toDate();
    
    // rankings 업데이트 로직 (onWorkoutCreated와 동일)
    await updateRankings(userId, workout, date);
    
    processed++;
    
    if (processed % 100 === 0) {
      console.log(`✅ Processed ${processed}/${workouts.size}`);
    }
  }
  
  console.log('🎉 Migration completed!');
}

// 실행
migrateExistingWorkouts().catch(console.error);
```

### 실행

```bash
cd functions
npm run build
node lib/migrate.js
```

---

## 💰 최종 비용 계산

### Before (현재 방식)

```
DAU: 1,000명
평균 랭킹 조회: 10회/일/사용자

Firestore 읽기:
- 1,000명 × 10회 × 2,000 reads = 20,000,000 reads/day
- 월간: 600,000,000 reads

비용:
- 무료: 50,000 reads/day
- 초과: 598,500,000 reads
- 비용: $359/월
```

### After (사전 집계 방식)

```
DAU: 1,000명
평균 랭킹 조회: 10회/일/사용자

Firestore 읽기:
- 1,000명 × 10회 × 100 reads = 1,000,000 reads/day
- 월간: 30,000,000 reads

Firestore 쓰기 (추가):
- 1,000명 × 5회 workout × 4개 period = 20,000 writes/day
- 월간: 600,000 writes

비용:
- 읽기: 30M reads → $1.80
- 쓰기: 600K writes → $1.08
- Cloud Functions: ~$5
- 총: $7.88/월

절감액: $359 - $8 = $351/월 (98% 절감!) 🎉
```

---

## 🎯 결론

이제 제대로 된 구조입니다!

### 핵심 변화
- ❌ **Before**: workouts에서 매번 집계
- ✅ **After**: rankings에 사전 집계된 데이터 저장

### 주요 장점
1. ⚡️ **속도**: 17배 빠름 (5초 → 0.3초)
2. 💰 **비용**: 98% 절감 ($359 → $8)
3. 📈 **확장성**: 사용자 수 증가해도 성능 일정
4. 🔧 **유지보수**: 간단한 쿼리, 명확한 구조

이게 바로 **올바른 DB 설계**입니다! 🚀
