# 팔로우 시스템 구현 가이드

## 개요

사용자 간 팔로우/팔로잉 관계를 구축하고, 다른 사용자의 프로필 및 통계를 확인할 수 있는 소셜 기능을 구현했습니다. 커뮤니티와 랭킹 페이지에서 사용자를 클릭하면 상세 프로필을 볼 수 있습니다.

## 주요 기능

### 1. 팔로우/팔로잉 시스템
- 다른 사용자 팔로우/언팔로우 기능
- 팔로워 및 팔로잉 수 실시간 표시
- Firestore를 통한 팔로우 관계 영구 저장

### 2. 사용자 프로필 화면
- 사용자의 운동 통계 및 정보 표시
- 팔로워/팔로잉/운동일 수 표시
- 연속 운동 일수(Streak) 표시
- 사용자의 최근 게시글 표시
- 탭 구조로 운동 통계와 게시글 분리

### 3. 사용자 카드 위젯
- 간단한 사용자 정보 표시 (UserCard)
- 상세한 사용자 정보 바텀시트 (UserDetailCard)
- Hero 애니메이션을 통한 부드러운 전환

### 4. 커뮤니티 및 랭킹 연동
- 랭킹 화면에서 사용자 항목 클릭 시 프로필 바텀시트 표시
- 커뮤니티 화면에서 게시글 작성자 클릭 시 프로필 바텀시트 표시

## 데이터 모델

### FollowModel
```dart
class FollowModel {
  String id;                // 문서 ID (followerId_followingId)
  String followerId;        // 팔로우하는 사용자 ID
  String followingId;       // 팔로우 당하는 사용자 ID
  DateTime createdAt;       // 팔로우 시작 시간
}
```

### UserProfileModel
```dart
class UserProfileModel {
  String userId;
  String displayName;
  String? photoURL;
  String? bio;              // 자기소개
  int totalSquats;
  int totalLunges;
  int totalWalkSteps;
  double totalRunDistance;
  int totalWorkoutDays;
  int followerCount;        // 팔로워 수
  int followingCount;       // 팔로잉 수
  bool isFollowing;         // 현재 사용자가 팔로우 중인지
  int streak;               // 연속 운동 일수
}
```

### UserModel (업데이트)
기존 UserModel에 다음 필드 추가:
- `String? bio` - 사용자 자기소개
- `int followerCount` - 팔로워 수
- `int followingCount` - 팔로잉 수

## Firestore 구조

### follows 컬렉션
```
follows/
  {followerId}_{followingId}/
    id: string
    followerId: string
    followingId: string
    createdAt: timestamp
```

### users 컬렉션 (업데이트)
```
users/
  {userId}/
    ...기존 필드들
    bio: string (optional)
    followerCount: number
    followingCount: number
```

## Repository

### FollowRepository

#### 주요 메서드
- `followUser(followerId, followingId)` - 사용자 팔로우
- `unfollowUser(followerId, followingId)` - 사용자 언팔로우
- `isFollowing(followerId, followingId)` - 팔로우 상태 확인
- `getFollowers(userId)` - 팔로워 목록 스트림
- `getFollowing(userId)` - 팔로잉 목록 스트림
- `getFollowerCount(userId)` - 팔로워 수 조회
- `getFollowingCount(userId)` - 팔로잉 수 조회
- `getUserProfile(userId, currentUserId)` - 사용자 프로필 정보 조회
- `getUserPosts(userId)` - 사용자 게시글 스트림

#### 특징
- 자기 자신을 팔로우하는 것 방지
- 팔로우/언팔로우 시 양쪽 사용자의 카운트 자동 업데이트
- 운동 통계를 실시간으로 집계하여 프로필 정보 제공
- 연속 운동 일수(Streak) 자동 계산

## Providers

### followRepositoryProvider
`FollowRepository` 인스턴스 제공

### userProfileProvider
특정 사용자의 프로필 정보를 제공하는 `FutureProvider.family`

### isFollowingProvider
현재 사용자가 특정 사용자를 팔로우 중인지 여부를 제공하는 `FutureProvider.family`

### followersProvider
특정 사용자의 팔로워 목록을 제공하는 `StreamProvider.family`

### followingProvider
특정 사용자의 팔로잉 목록을 제공하는 `StreamProvider.family`

### followerCountProvider
특정 사용자의 팔로워 수를 제공하는 `FutureProvider.family`

### followingCountProvider
특정 사용자의 팔로잉 수를 제공하는 `FutureProvider.family`

### userPostsProvider
특정 사용자의 최근 게시글을 제공하는 `StreamProvider.family`

### followNotifierProvider
팔로우/언팔로우 액션을 처리하는 `StateNotifierProvider`

## UI 컴포넌트

### UserProfileScreen
전체 화면 사용자 프로필

**특징:**
- SliverAppBar를 사용한 스크롤 가능한 헤더
- TabBar를 통한 운동 통계 / 게시글 탭 전환
- 팔로우/언팔로우 버튼 (다른 사용자의 경우)
- 프로필 편집 버튼 (본인 프로필의 경우)
- Hero 애니메이션을 통한 부드러운 화면 전환

**네비게이션:**
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => UserProfileScreen(userId: userId),
  ),
);
```

### UserCard
간단한 사용자 정보 카드 위젯

**사용법:**
```dart
UserCard(
  userId: user.userId,
  displayName: user.displayName,
  photoURL: user.photoURL,
  trailing: Text('1위'), // 선택적
  onTap: () {
    // 커스텀 액션
  },
)
```

### UserDetailCard
바텀시트로 표시되는 상세 사용자 정보 카드

**사용법:**
```dart
UserDetailCard.show(context, userId);
```

**특징:**
- 바텀시트 형태로 표시
- 팔로우/언팔로우 버튼
- 프로필 보기 버튼 (전체 프로필 화면으로 이동)
- 간단한 운동 통계 표시
- 드래그 핸들을 통한 직관적인 UX

## 사용 예시

### 랭킹 화면에서 사용자 클릭
```dart
Widget _buildRankingItem(RankingModel ranking, bool isCurrentUser) {
  return GestureDetector(
    onTap: () {
      UserDetailCard.show(context, ranking.userId);
    },
    child: Container(
      // ... 랭킹 아이템 UI
    ),
  );
}
```

### 커뮤니티 화면에서 작성자 클릭
```dart
GestureDetector(
  onTap: () {
    UserDetailCard.show(context, post.userId);
  },
  child: Row(
    children: [
      Hero(
        tag: 'user_avatar_${post.userId}',
        child: // ... 사용자 아바타
      ),
      // ... 사용자 정보
    ],
  ),
)
```

### 팔로우/언팔로우
```dart
ElevatedButton(
  onPressed: () async {
    await ref
        .read(followNotifierProvider.notifier)
        .toggleFollow(userId);
  },
  child: Text(isFollowing ? '팔로잉' : '팔로우'),
)
```

## 주요 로직

### 연속 운동 일수(Streak) 계산
```dart
Future<int> _calculateStreak(String userId) async {
  // 1. 사용자의 모든 운동 기록을 날짜순 정렬로 가져옴
  // 2. 오늘 또는 어제에 운동이 없으면 streak = 0
  // 3. 연속된 날짜를 역순으로 카운트
  // 4. 연속이 끊기면 중단
  return streak;
}
```

### 팔로우 카운트 자동 업데이트
```dart
Future<void> _updateFollowCounts(String followerId, String followingId) async {
  // 1. followingId 사용자의 팔로워 수 재계산 및 업데이트
  final followerCount = await getFollowerCount(followingId);
  await _firestore.collection('users').doc(followingId).update({
    'followerCount': followerCount,
  });
  
  // 2. followerId 사용자의 팔로잉 수 재계산 및 업데이트
  final followingCount = await getFollowingCount(followerId);
  await _firestore.collection('users').doc(followerId).update({
    'followingCount': followingCount,
  });
}
```

### 사용자 프로필 정보 조회
```dart
Future<UserProfileModel> getUserProfile(String userId, String currentUserId) async {
  // 1. 사용자 기본 정보 조회
  final userDoc = await _firestore.collection('users').doc(userId).get();
  
  // 2. 팔로우 관련 정보 조회
  final followerCount = await getFollowerCount(userId);
  final followingCount = await getFollowingCount(userId);
  final isFollowing = await this.isFollowing(currentUserId, userId);
  
  // 3. 운동 통계 집계
  final workoutSnapshot = await _firestore
      .collection('workouts')
      .where('userId', isEqualTo: userId)
      .get();
  
  // 4. 연속 운동 일수 계산
  final streak = await _calculateStreak(userId);
  
  // 5. UserProfileModel 생성 및 반환
  return UserProfileModel(...);
}
```

## 보안 고려사항

1. **자기 자신 팔로우 방지**
   - `followUser` 메서드에서 `followerId == followingId` 체크

2. **인증 확인**
   - 모든 팔로우 관련 액션은 로그인된 사용자만 가능
   - Provider에서 `currentUser == null` 체크

3. **데이터 일관성**
   - 팔로우/언팔로우 시 양쪽 카운트 자동 업데이트
   - Provider invalidation을 통한 UI 자동 갱신

## 성능 최적화

1. **효율적인 쿼리**
   - 팔로우 관계는 복합 키 사용 (`{followerId}_{followingId}`)
   - 인덱스를 활용한 빠른 조회

2. **캐싱**
   - Riverpod의 자동 캐싱 활용
   - FutureProvider와 StreamProvider로 중복 요청 방지

3. **지연 로딩**
   - 사용자 게시글은 limit을 두어 최근 10개만 로드
   - 필요시 페이지네이션 추가 가능

## 향후 개선 사항

1. **메시지 기능**
   - 팔로우한 사용자와 메시지 주고받기
   - 현재는 placeholder로 준비 중 메시지 표시

2. **프로필 편집**
   - 자기소개(bio) 수정
   - 프로필 사진 변경
   - 현재는 placeholder로 준비 중 메시지 표시

3. **팔로워/팔로잉 목록 화면**
   - 팔로워 및 팔로잉 목록을 별도 화면으로 표시
   - 각 사용자의 간단한 정보와 팔로우 버튼 제공

4. **활동 피드**
   - 팔로우한 사용자들의 최근 운동 기록 표시
   - 팔로우한 사용자들의 게시글 피드

5. **알림**
   - 누군가 나를 팔로우했을 때 알림
   - 팔로우한 사용자가 운동 기록을 달성했을 때 알림

6. **게시글 상세 화면**
   - 게시글 클릭 시 상세 화면 표시
   - 현재는 placeholder

## 문제 해결

### 문제: 팔로워 수가 실시간으로 업데이트되지 않음
**해결:**
```dart
// 팔로우/언팔로우 후 관련 Provider invalidate
ref.invalidate(userProfileProvider(userId));
ref.invalidate(isFollowingProvider(userId));
```

### 문제: Hero 애니메이션이 작동하지 않음
**해결:**
- 모든 아바타에 동일한 Hero tag 사용: `'user_avatar_$userId'`
- 각 화면과 위젯에서 일관된 Hero 위젯 사용

### 문제: 자기 자신의 프로필에서 팔로우 버튼이 보임
**해결:**
```dart
final isOwnProfile = currentUser?.uid == userId;
if (!isOwnProfile) {
  // 팔로우 버튼 표시
}
```

## 결론

팔로우 시스템은 사용자 간의 소셜 연결을 강화하고, 커뮤니티 활동을 촉진합니다. 
사용자는 다른 사용자의 운동 기록과 게시글을 확인하며 동기부여를 받을 수 있으며, 
친구들과의 경쟁과 협력을 통해 꾸준한 운동 습관을 형성할 수 있습니다.

구현된 기능은 확장 가능한 구조로 설계되어, 향후 메시지, 프로필 편집, 활동 피드 등의 
고급 소셜 기능을 쉽게 추가할 수 있습니다.
