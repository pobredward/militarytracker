# 랭킹 시스템 구현 가이드

## 📊 개요

밀리터리트래커 앱의 종합 랭킹 시스템입니다. 사용자들의 운동 성과를 다양한 기준으로 순위화하고, 경쟁과 동기부여를 제공합니다.

## 🎯 시스템 설계 철학

### 마케팅 & 사용자 경험 관점

**하이브리드 접근 방식 채택:**

1. **메인: 종합 랭킹 (Overall Score)**
   - 모든 운동을 균형있게 수행하도록 유도
   - 건강한 운동 습관 형성
   - 하나의 운동만 과도하게 하는 것 방지

2. **서브: 운동별 랭킹**
   - 특정 운동에 특화된 사용자도 성취감 획득
   - 다양한 경쟁 구조로 재방문 유도
   - 세분화된 목표 설정 가능

3. **기간별 필터**
   - 일간: 오늘의 실시간 경쟁
   - 주간: 이번 주 목표 (월요일 시작)
   - 월간: 이번 달 누적 성과
   - 전체: 역대 최고 기록

## 🧮 점수 계산 로직

### 종합 점수 (Overall Score) 공식

```dart
종합 점수 = (스쿼트 × 1.2) + (런지 × 1.2) + (걷기 × 0.01) + (뛰기 × 150)
```

### 가중치 설명

| 운동 | 가중치 | 이유 |
|------|--------|------|
| **스쿼트** | 1.2 | 고강도 하체 운동, 기술이 필요 |
| **런지** | 1.2 | 고강도 하체 운동, 균형감 필요 |
| **걷기** | 0.01 | 저강도 운동, 많은 양 가능 (100보 = 1점) |
| **뛰기** | 150 | 최고 강도 유산소, 체력 소모 큼 (1km = 150점) |

### 예시 계산

```
사용자 A:
- 스쿼트: 50회 → 60점
- 런지: 50회 → 60점
- 걷기: 10,000보 → 100점
- 뛰기: 3km → 450점
----------------------------
종합 점수: 670점

사용자 B (스쿼트만 집중):
- 스쿼트: 500회 → 600점
- 런지: 0회 → 0점
- 걷기: 0보 → 0점
- 뛰기: 0km → 0점
----------------------------
종합 점수: 600점

→ 사용자 A가 더 높은 순위!
```

## 🏗️ 아키텍처

### 파일 구조

```
lib/
├── models/
│   ├── ranking_model.dart           # 랭킹 데이터 모델
│   ├── ranking_model.freezed.dart   # (자동 생성)
│   └── ranking_model.g.dart         # (자동 생성)
├── repositories/
│   └── ranking_repository.dart      # 랭킹 데이터 처리
├── providers/
│   ├── ranking_provider.dart        # 랭킹 상태 관리
│   └── navigation_provider.dart     # 네비게이션 상태 관리
└── features/
    └── ranking/
        └── presentation/
            └── ranking_screen.dart  # 랭킹 UI
```

## 📱 주요 기능

### 1. 기간별 랭킹

```dart
enum RankingPeriod {
  daily,   // 일간: 오늘 00:00 ~ 23:59
  weekly,  // 주간: 이번 주 월요일 ~ 현재
  monthly, // 월간: 이번 달 1일 ~ 현재
  allTime, // 전체: 모든 기간
}
```

### 2. 카테고리별 랭킹

```dart
enum RankingCategory {
  overall,  // 종합: 가중치 적용 점수
  squats,   // 스쿼트: 순수 횟수
  lunges,   // 런지: 순수 횟수
  walking,  // 걷기: 순수 걸음 수
  running,  // 뛰기: 순수 거리 (km)
}
```

### 3. 동점자 처리

```dart
// 예시: 1등, 1등, 3등, 4등, 4등, 6등...
// 동점자는 같은 순위를 받고, 다음 순위는 건너뜁니다.

if (i > 0 && score < previousScore!) {
  currentRank = i + 1;  // 실제 순서를 순위로 사용
}
```

### 4. 0점 사용자 제외

```dart
// 실제 운동을 한 사용자만 랭킹에 표시
rankings.removeWhere((r) {
  final score = r.getScoreForCategory(category);
  return score == 0;
});
```

## 🎨 UI/UX 특징

### 메달 시스템

- 🥇 **1등**: 골드 그라데이션 + 프리미엄 아이콘
- 🥈 **2등**: 실버 그라데이션 + 프리미엄 아이콘
- 🥉 **3등**: 브론즈 그라데이션 + 프리미엄 아이콘
- 📊 **4등 이하**: 일반 배지

### 색상 테마

| 요소 | 색상 | 용도 |
|------|------|------|
| Primary | `#FF9800` (Orange) | 랭킹 강조색 |
| Gold | `#FFD700` | 1등 메달 |
| Silver | `#C0C0C0` | 2등 메달 |
| Bronze | `#CD7F32` | 3등 메달 |
| Accent | `#00C853` (Green) | 사용자 강조 |

### 애니메이션

```dart
// 리스트 아이템 순차적 등장
Interval(
  (index * 0.05).clamp(0.0, 1.0),
  ((index * 0.05) + 0.3).clamp(0.0, 1.0),
  curve: Curves.easeOutCubic,
)
```

### 내 랭킹 카드

- 오렌지 하이라이트
- 상단 고정 표시
- 한눈에 내 위치 파악 가능

## 🔥 성능 최적화

### 1. 자동 캐싱

```dart
final rankingListProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) async {
  // autoDispose: 화면을 벗어나면 자동으로 메모리 해제
});
```

### 2. 데이터 제한

```dart
// 상위 100명만 조회
rankings.take(limit).toList()  // limit = 100
```

### 3. 선택적 조회

```dart
// 필요한 기간/카테고리만 조회
final period = ref.watch(selectedRankingPeriodProvider);
final category = ref.watch(selectedRankingCategoryProvider);
```

## 📊 Firebase 데이터 구조

### Collections 사용

```
users/
  ├── {userId}/
  │   ├── displayName: string
  │   ├── photoUrl: string
  │   └── ...
  
workouts/
  ├── {workoutId}/
  │   ├── userId: string
  │   ├── date: Timestamp
  │   ├── squatCount: number
  │   ├── lungeCount: number
  │   ├── walkSteps: number
  │   ├── runDistance: number
  │   └── ...
```

### 쿼리 예시

```dart
// 이번 주 월요일부터 오늘까지의 운동 데이터
_firestore
  .collection('workouts')
  .where('userId', isEqualTo: userId)
  .where('date', isGreaterThanOrEqualTo: startOfWeek)
  .where('date', isLessThanOrEqualTo: today)
  .get()
```

## 🚀 사용 방법

### 화면 네비게이션

```dart
// 홈 화면에서 랭킹 화면으로 이동
ref.read(navigationIndexProvider.notifier).state = 3;
```

### 랭킹 데이터 조회

```dart
// Provider 사용
final rankings = ref.watch(rankingListProvider);

rankings.when(
  data: (list) => _buildRankingList(list),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => ErrorWidget(error),
);
```

### 수동 새로고침

```dart
// 새로고침 버튼
IconButton(
  onPressed: () => ref.refresh(rankingListProvider),
  icon: Icon(Icons.refresh_rounded),
)
```

## ⚠️ 알려진 제약사항

### 1. 성능 제약

- **N+1 쿼리 문제**: 모든 사용자를 조회한 후 각 사용자의 운동 데이터를 조회
- **개선 방안**: 사용자가 많아지면 Cloud Functions로 집계 처리 필요

### 2. 실시간 업데이트

- 현재는 수동 새로고침 방식
- 실시간 업데이트를 위해서는 StreamProvider로 전환 필요

### 3. 캐싱 전략

- 현재는 화면 진입 시마다 조회
- 개선: 로컬 캐싱 + 주기적 동기화

## 🔮 향후 개선 계획

### 1. 성능 최적화

```dart
// Cloud Functions로 집계 처리
// 매일 자동으로 랭킹 계산하여 별도 컬렉션에 저장

rankings_daily/
  └── {date}/
      └── {category}/
          └── rankings: [...]
```

### 2. 실시간 순위 변동

```dart
// StreamProvider로 실시간 업데이트
final rankingStreamProvider = StreamProvider.autoDispose<List<RankingModel>>((ref) {
  return _firestore
    .collection('rankings_cache')
    .orderBy('score', descending: true)
    .snapshots()
    .map((snapshot) => ...);
});
```

### 3. 추가 기능

- [ ] 친구 랭킹 (팔로우한 사용자만)
- [ ] 지역별 랭킹
- [ ] 나이대별 랭킹
- [ ] 성별 랭킹
- [ ] 주간/월간 우승자 명예의 전당
- [ ] 랭킹 상승/하락 표시 (🔺🔻)
- [ ] 달성 배지 시스템

### 4. 게임화 요소

- [ ] 레벨 시스템 (점수 구간별 레벨)
- [ ] 업적 시스템
- [ ] 연속 운동 일수 (Streak)
- [ ] 도전 과제 (Challenges)

## 🧪 테스트 시나리오

### 1. 기본 동작 확인

```
1. 앱 실행 → 랭킹 탭 이동
2. 기간 선택 (일간/주간/월간/전체)
3. 카테고리 선택 (종합/스쿼트/런지/걷기/뛰기)
4. 랭킹 리스트 확인
5. 내 랭킹 카드 확인
```

### 2. 동점자 처리 확인

```
같은 점수를 가진 사용자들이 같은 순위를 받는지 확인
다음 순위가 올바르게 건너뛰어지는지 확인
```

### 3. 0점 사용자 제외 확인

```
운동을 전혀 하지 않은 사용자가 랭킹에 나타나지 않는지 확인
```

### 4. 날짜 범위 확인

```
일간: 오늘 데이터만
주간: 이번 주 월요일부터
월간: 이번 달 1일부터
전체: 모든 데이터
```

## 💡 팁 & 베스트 프랙티스

### 1. 효율적인 데이터 조회

```dart
// 필요한 필드만 선택
.select(['displayName', 'photoUrl'])
```

### 2. 에러 처리

```dart
try {
  final rankings = await getRankings(...);
} catch (e) {
  // 사용자에게 친화적인 에러 메시지 표시
  showErrorSnackBar('랭킹을 불러올 수 없습니다');
}
```

### 3. 로딩 상태 관리

```dart
rankings.when(
  data: (list) => _buildRankingList(list),
  loading: () => ShimmerLoading(), // 스켈레톤 UI
  error: (error, _) => RetryButton(),
);
```

## 📚 참고 자료

- [Flutter Riverpod 공식 문서](https://riverpod.dev/)
- [Cloud Firestore 쿼리 가이드](https://firebase.google.com/docs/firestore/query-data/queries)
- [Freezed 패키지](https://pub.dev/packages/freezed)

## 📝 변경 이력

### 2024-12-27
- ✅ 초기 랭킹 시스템 구현
- ✅ 종합 점수 계산 로직 구현
- ✅ 5가지 카테고리 랭킹 구현
- ✅ 4가지 기간 필터 구현
- ✅ 동점자 처리 로직 구현
- ✅ UI/UX 디자인 완료
- ✅ 애니메이션 적용

---

**구현 완료!** 🎉

모든 랭킹 시스템이 정상적으로 작동하며, Firebase와 완벽하게 연동되어 있습니다.
