# 랭킹 저장 방식 비교: users vs rankings 컬렉션

## 🎯 제안: users 컬렉션에 모든 통계 저장

```
users/
  {userId}/
    - displayName: "홍길동"
    - photoUrl: "..."
    - stats/
        daily/
          2024-01-15/
            - squatCount: 50
            - lungeCount: 30
            - overallScore: 100
        weekly/
          2024-W03/
            - squatCount: 350
            - overallScore: 700
        monthly/
          2024-01/
            - squatCount: 1500
            - overallScore: 3000
        allTime/
          - squatCount: 10000
          - overallScore: 20000
```

---

## 📊 방법 비교

### 방법 1: rankings 컬렉션 (제가 제안한 것)

```
rankings/
  daily/
    2024-01-15/
      {userId}/...
  weekly/
    2024-W03/
      {userId}/...
```

**랭킹 조회 (월간 스쿼트)**:
```dart
_firestore
  .collection('rankings')
  .doc('monthly')
  .collection('2024-01')
  .orderBy('squatCount', descending: true)
  .limit(100)
  .get();
```
✅ **1개 쿼리**, 100개 문서

---

### 방법 2: users 컬렉션에 저장 (당신의 제안)

```
users/
  {userId}/
    - displayName: "홍길동"
    - stats/
        monthly/
          2024-01/...
```

**랭킹 조회 (월간 스쿼트)**:
```dart
// ❌ 불가능! collectionGroup으로도 정렬이 안됨
_firestore
  .collectionGroup('monthly')
  .where(FieldPath.documentId, isEqualTo: '2024-01')
  .orderBy('squatCount', descending: true)  // ❌ 에러!
  .limit(100)
  .get();
```

**이유**: Firestore는 다른 문서의 서브컬렉션을 정렬할 수 없습니다!

**대안**: 모든 사용자를 다 읽어서 클라이언트에서 정렬
```dart
// 모든 사용자 읽기 (비효율!)
final users = await _firestore.collection('users').get();

List<RankingData> rankings = [];
for (var userDoc in users.docs) {
  final monthlyDoc = await userDoc.reference
    .collection('stats')
    .doc('monthly')
    .collection('2024-01')
    .doc('2024-01')
    .get();
  
  if (monthlyDoc.exists) {
    rankings.add(RankingData(
      userId: userDoc.id,
      squatCount: monthlyDoc.data()!['squatCount'],
    ));
  }
}

// 클라이언트에서 정렬
rankings.sort((a, b) => b.squatCount.compareTo(a.squatCount));
```

❌ **1,000개 users + 1,000개 stats = 2,000 reads!**

---

## 🔥 방법 3: users 컬렉션 최상위에 저장 (개선안)

```
users/
  {userId}/
    - displayName: "홍길동"
    - photoUrl: "..."
    
    // 일간 통계
    - dailySquats_2024-01-15: 50
    - dailyLunges_2024-01-15: 30
    - dailyOverall_2024-01-15: 100
    
    // 주간 통계
    - weeklySquats_2024-W03: 350
    - weeklyLunges_2024-W03: 210
    - weeklyOverall_2024-W03: 700
    
    // 월간 통계
    - monthlySquats_2024-01: 1500
    - monthlyLunges_2024-01: 900
    - monthlyOverall_2024-01: 3000
    
    // 전체 통계
    - allTimeSquats: 10000
    - allTimeLunges: 6000
    - allTimeOverall: 20000
```

**랭킹 조회 (월간 스쿼트)**:
```dart
_firestore
  .collection('users')
  .orderBy('monthlySquats_2024-01', descending: true)
  .limit(100)
  .get();
```

✅ **1개 쿼리**, 100개 문서!

---

## 💰 성능 & 비용 비교

### 시나리오: DAU 1,000명, 월간 스쿼트 랭킹 조회

| 방법 | 쿼리 수 | 읽기 | 쓰기 | 인덱스 | 난이도 |
|------|---------|------|------|--------|--------|
| **rankings 컬렉션** | 1 | 100 | 4 | 5개 | 중간 |
| **users 서브컬렉션** | 2,000 | 2,000 | 4 | - | 높음 |
| **users 최상위 필드** | 1 | 100 | 4 | 120개 😱 | 낮음 |

---

## 🤔 방법 3 (users 최상위 필드)의 문제점

### 문제 1: 필드 폭발 🤯

```
users/{userId}/
  - dailySquats_2024-01-01: 50
  - dailySquats_2024-01-02: 30
  - dailySquats_2024-01-03: 40
  ... (365일)
  - weeklySquats_2024-W01: 350
  - weeklySquats_2024-W02: 400
  ... (52주)
  - monthlySquats_2024-01: 1500
  - monthlySquats_2024-02: 1300
  ... (12개월)
  
= 매년 400+ 개의 필드!
```

**Firestore 제한**: 문서당 최대 **20,000개 필드**  
→ 50년 후에나 문제 😅

### 문제 2: 인덱스 폭발 😱

매일 새로운 필드 → 매일 새로운 인덱스 필요!

```
// 매일 생성해야 하는 인덱스
- monthlySquats_2024-01 (DESC)
- monthlySquats_2024-02 (DESC)
- monthlySquats_2024-03 (DESC)
...

= 월 12개 × 카테고리 5개 = 60개 인덱스/년
```

**Firestore 제한**: 프로젝트당 최대 **200개 복합 인덱스**

### 문제 3: 쿼리 복잡도

```dart
// 현재 월 키 계산
final monthKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

// 쿼리
_firestore
  .collection('users')
  .orderBy('monthlySquats_$monthKey', descending: true)  // 동적 필드명!
  .limit(100)
  .get();
```

---

## 🏆 방법 4: 하이브리드 (최적안!)

### 구조

```
users/
  {userId}/
    - displayName: "홍길동"
    - photoUrl: "..."
    
    // 현재 기간 통계만 최상위 (빠른 조회)
    - currentDailySquats: 50        ← 오늘
    - currentWeeklySquats: 350      ← 이번 주
    - currentMonthlySquats: 1500    ← 이번 달
    - allTimeSquats: 10000          ← 전체
    
    - currentDailyLunges: 30
    - currentWeeklyLunges: 210
    - currentMonthlyLunges: 900
    - allTimeLunges: 6000
    
    - currentDailyOverall: 100
    - currentWeeklyOverall: 700
    - currentMonthlyOverall: 3000
    - allTimeOverall: 20000
    
    // 마지막 업데이트 날짜
    - lastDailyUpdate: "2024-01-15"
    - lastWeeklyUpdate: "2024-W03"
    - lastMonthlyUpdate: "2024-01"

rankings/
  history/
    daily/
      2024-01-14/
        {userId}/...  ← 과거 데이터만 저장
    weekly/
      2024-W02/
        {userId}/...
    monthly/
      2023-12/
        {userId}/...
```

### 랭킹 조회

```dart
// 현재 기간 (오늘, 이번 주, 이번 달)
_firestore
  .collection('users')
  .orderBy('currentMonthlySquats', descending: true)
  .limit(100)
  .get();

// 100 reads! ✅

// 과거 기간
_firestore
  .collection('rankings')
  .doc('history')
  .collection('monthly')
  .doc('2023-12')
  .collection('users')
  .orderBy('squatCount', descending: true)
  .limit(100)
  .get();
```

### 운동 완료 시

```dart
Future<void> updateStats(WorkoutModel workout) async {
  final userId = workout.userId;
  final now = DateTime.now();
  
  final userRef = _firestore.collection('users').doc(userId);
  final userData = await userRef.get();
  
  // 날짜 변경 체크
  final lastDaily = userData.data()?['lastDailyUpdate'];
  final today = _formatDate(now, 'YYYY-MM-DD');
  
  Map<String, dynamic> updates = {};
  
  if (lastDaily != today) {
    // 새로운 날 → 일간 초기화
    updates['currentDailySquats'] = workout.squatCount;
    updates['lastDailyUpdate'] = today;
    
    // 어제 데이터를 history에 저장
    if (lastDaily != null) {
      await _archiveDaily(userId, lastDaily, userData.data()!);
    }
  } else {
    // 같은 날 → 증가
    updates['currentDailySquats'] = FieldValue.increment(workout.squatCount);
  }
  
  // 주간, 월간도 동일 로직
  // ...
  
  // 전체는 항상 증가
  updates['allTimeSquats'] = FieldValue.increment(workout.squatCount);
  
  await userRef.update(updates);
}
```

---

## 🎯 최종 비교

### 사용 사례별 추천

#### Case 1: 사용자 < 100명
```
방법: workouts에서 실시간 집계
이유: 무료, 간단
비용: $0
```

#### Case 2: 사용자 100-1,000명, 현재 기간만 필요
```
방법: users 최상위 필드 (current*)
이유: 간단, 빠름, 인덱스 고정
비용: $2/월
```

#### Case 3: 사용자 100-1,000명, 과거 데이터 필요
```
방법: 하이브리드 (users + rankings history)
이유: 현재는 빠르고, 과거도 조회 가능
비용: $5/월
```

#### Case 4: 사용자 > 1,000명
```
방법: rankings 컬렉션
이유: 최고 성능, 무한 확장
비용: $10/월
```

---

## 💡 당신의 질문에 대한 답변

> "users DB에 일간, 주간, 월간, 전체 기록을 다 저장한다면?"

### ✅ 장점
1. **간단함**: 한 곳에 모든 데이터
2. **빠른 조회**: 사용자 정보와 통계 동시 조회
3. **일관성**: 사용자 문서에 모든 것

### ❌ 단점
1. **필드 폭발**: 매일 새 필드 생성
2. **인덱스 문제**: 동적 필드명으로 인덱스 관리 어려움
3. **과거 데이터**: 매일/매주/매월 축적 → 문서 비대

### 🏆 최적안: 하이브리드

```
users/
  {userId}/
    - currentDailySquats: 50     ← 고정 필드명!
    - currentWeeklySquats: 350
    - currentMonthlySquats: 1500
    - allTimeSquats: 10000

rankings/
  history/  ← 과거 데이터만
```

**이유**:
- ✅ 현재 랭킹: users에서 빠르게 조회
- ✅ 과거 랭킹: rankings에서 조회
- ✅ 필드 수 고정: 20개 정도
- ✅ 인덱스 고정: 5개만 필요

---

## 📊 성능 비교표

| 방법 | 현재 랭킹 | 과거 랭킹 | 필드 수 | 인덱스 수 | 복잡도 | 추천도 |
|------|----------|----------|---------|----------|--------|--------|
| **rankings 전용** | 100 reads | 100 reads | 0 | 5 | 중 | ⭐️⭐️⭐️⭐️ |
| **users 서브컬렉션** | 2,000 reads | 2,000 reads | 0 | 0 | 높음 | ❌ |
| **users 동적 필드** | 100 reads | 100 reads | 400+/년 | 60/년 | 높음 | ❌ |
| **users 고정 필드** | 100 reads | 불가 | 20 | 5 | 낮음 | ⭐️⭐️⭐️ |
| **하이브리드** | 100 reads | 100 reads | 20 | 5 | 중 | ⭐️⭐️⭐️⭐️⭐️ |

---

## 🎯 최종 결론

### 추천: 하이브리드 방식

```dart
// 장점 조합
1. users 컬렉션: 현재 기간 (빠름!)
2. rankings 컬렉션: 과거 기간 (완전함!)
3. 필드 고정: 유지보수 쉬움
4. 인덱스 고정: 관리 쉬움
```

### 구현 순서

1. **지금 당장**: 아무것도 안 함 (현재 방식 유지)
2. **사용자 100명 돌파**: users에 current* 필드 추가
3. **과거 데이터 필요 시**: rankings history 추가

코드 구현해드릴까요? 🚀
