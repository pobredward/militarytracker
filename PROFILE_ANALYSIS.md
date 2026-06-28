# 🧑 Profile & 마이페이지 종합 분석 리포트

**분석 일자:** 2026년 3월 23일  
**분석 대상:** Profile, EditProfile, UserProfile 화면 및 관련 로직

---

## 📊 현재 구조 분석

### 파일 구조
```
lib/features/profile/presentation/
├── profile_screen.dart           (본인 프로필 - 마이페이지)
├── edit_profile_screen.dart      (프로필 편집)
├── user_profile_screen.dart      (다른 사용자 프로필)
├── statistics_screen.dart        (통계)
├── achievements_screen.dart      (업적)
├── workout_history_screen.dart   (운동 기록)
├── notification_settings_screen.dart
└── help_screen.dart

lib/models/
├── user_model.dart               (본인 사용자 정보)
└── user_profile_model.dart       (다른 사용자 프로필)

lib/providers/
└── follow_provider.dart          (팔로우 기능)
```

---

## 🔴 치명적 이슈 (즉시 수정 필요)

### 1. **Result 패턴 미적용** ⚠️⚠️⚠️⚠️⚠️

**위치:** `profile_screen.dart:484-493`, `edit_profile_screen.dart:222-229`

**문제:**
```dart
// profile_screen.dart (계정 삭제)
final error = await authActions.deleteAccount();
if (error != null && context.mounted) {  // ❌ Result<void> 타입인데 String?로 처리
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error)),  // ❌ 컴파일 에러
  );
}

// edit_profile_screen.dart (프로필 저장)
ScaffoldMessenger.of(context).showSnackBar(  // ❌ AppSnackBar 미사용
  SnackBar(content: Text('프로필 업데이트 실패: $e')),
);
```

**해결:**
```dart
// profile_screen.dart
final result = await authActions.deleteAccount();
result.when(
  success: (_) {
    if (context.mounted) {
      AppSnackBar.showSuccess(context, '계정이 삭제되었습니다');
    }
  },
  failure: (message, _) {
    if (context.mounted) {
      AppSnackBar.showError(context, message);
    }
  },
);

// edit_profile_screen.dart
AppSnackBar.showError(context, '프로필 업데이트 실패: $e');
```

---

## ⚠️ 심각한 문제

### 2. **print 문 남용** ⚠️⚠️⚠️

**위치:** `follow_provider.dart:93-96, 99-100, 112-113, 115-116`

**문제:**
```dart
print('🔍 Toggle Follow - userId: $userId, currentFollowing: $isFollowing');
print('👋 Unfollowing user: $userId');
print('👍 Following user: $userId');
print('✅ Toggle Follow completed successfully');
print('❌ Toggle Follow error: $e');
```

**해결:**
```dart
logger.d('Toggle Follow - userId: $userId, currentFollowing: $isFollowing');
logger.i('Unfollowing user: $userId');
logger.i('Following user: $userId');
logger.i('Toggle Follow completed successfully');
logger.e('Toggle Follow error', e);
```

---

### 3. **Unused Import** ⚠️⚠️

**위치:** `user_profile_screen.dart:6`

```dart
import '../../community/presentation/community_screen.dart';  // ❌ 미사용
```

---

### 4. **로그아웃 Result 패턴 미적용** ⚠️⚠️⚠️

**위치:** `profile_screen.dart:67`

```dart
if (confirm == true) {
  await authActions.signOut();  // ❌ Result<void> 반환값 무시
}
```

**해결:**
```dart
if (confirm == true) {
  final result = await authActions.signOut();
  result.when(
    success: (_) {
      // 로그아웃 성공 (자동으로 로그인 화면 이동)
    },
    failure: (message, _) {
      if (context.mounted) {
        AppSnackBar.showError(context, message);
      }
    },
  );
}
```

---

## 🐛 로직 개선 필요

### 5. **중복된 사용자 모델** ⚠️⚠️⚠️

**문제:** `UserModel`과 `UserProfileModel`이 거의 동일한 필드 보유

**현재:**
```dart
// user_model.dart (본인용)
class UserModel {
  String id;
  String email;
  String displayName;
  String? photoUrl;
  String? bio;
  int totalSquats;
  // ...
}

// user_profile_model.dart (다른 사용자용)
class UserProfileModel {
  String userId;
  String displayName;
  String? photoURL;  // ❌ 이름 불일치 (photoUrl vs photoURL)
  String? bio;
  int totalSquats;
  bool isFollowing;
  // ...
}
```

**개선안:**
```dart
// 1. 통합 모델 + Extension
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') String id,
    @Default('') String email,
    @Default('게스트') String displayName,
    String? photoUrl,
    String? bio,
    @Default('email') String authProvider,
    @Default(0) int totalSquats,
    @Default(0) int totalLunges,
    @Default(0) int totalWalkSteps,
    @Default(0.0) double totalRunDistance,
    @Default(0) int workoutDays,
    @Default(0) int followerCount,
    @Default(0) int followingCount,
    @Default(0) int streak,  // 추가: 연속 운동일
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

// Extension으로 추가 정보 제공
extension UserModelExtension on UserModel {
  // 다른 사용자 프로필로 변환 (팔로우 상태 추가)
  UserProfileView toProfileView({required bool isFollowing}) {
    return UserProfileView(
      user: this,
      isFollowing: isFollowing,
    );
  }
}

// 뷰 전용 wrapper
class UserProfileView {
  final UserModel user;
  final bool isFollowing;

  const UserProfileView({
    required this.user,
    required this.isFollowing,
  });
}
```

---

### 6. **프로필 이미지 삭제 로직 복잡도** ⚠️⚠️

**위치:** `edit_profile_screen.dart:154-235`

**문제:** 81줄의 복잡한 이미지 처리 로직

**개선안:**
```dart
// services/profile_image_service.dart (신규 생성)
class ProfileImageService {
  final StorageService _storageService = StorageService();
  
  /// 프로필 이미지 업데이트 처리
  Future<ProfileImageResult> updateProfileImage({
    required String userId,
    required String? currentPhotoUrl,
    File? newImage,
    bool deleteImage = false,
  }) async {
    try {
      // 1. 기존 이미지 삭제 (필요한 경우)
      if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) {
        if (newImage != null || deleteImage) {
          await _deleteOldImage(currentPhotoUrl);
        }
      }
      
      // 2. 새 이미지 업로드
      if (newImage != null) {
        final url = await _storageService.uploadProfileImage(newImage, userId);
        return ProfileImageResult.success(url);
      }
      
      // 3. 삭제만 하는 경우
      if (deleteImage) {
        return ProfileImageResult.deleted();
      }
      
      // 4. 변경사항 없음
      return ProfileImageResult.noChange(currentPhotoUrl);
    } catch (e) {
      return ProfileImageResult.error(e.toString());
    }
  }
  
  Future<void> _deleteOldImage(String url) async {
    try {
      await _storageService.deleteFile(url);
      logger.i('Old profile image deleted: $url');
    } catch (e) {
      logger.w('Failed to delete old image: $e');
      // 삭제 실패는 계속 진행
    }
  }
}

// Result 클래스
@freezed
class ProfileImageResult with _$ProfileImageResult {
  const factory ProfileImageResult.success(String? url) = _Success;
  const factory ProfileImageResult.deleted() = _Deleted;
  const factory ProfileImageResult.noChange(String? url) = _NoChange;
  const factory ProfileImageResult.error(String message) = _Error;
}

// 사용
final imageResult = await ProfileImageService().updateProfileImage(
  userId: user.id,
  currentPhotoUrl: user.photoUrl,
  newImage: _selectedImage,
  deleteImage: _currentPhotoUrl == null,
);

imageResult.when(
  success: (url) => /* 업데이트 */,
  deleted: () => /* 삭제 처리 */,
  noChange: (url) => /* 변경 없음 */,
  error: (msg) => /* 에러 처리 */,
);
```

---

### 7. **팔로우 상태 중복 확인** ⚠️⚠️

**위치:** `follow_provider.dart:78-101`

**문제:**
```dart
Future<void> toggleFollow(String userId) async {
  // 최신 팔로우 상태를 다시 확인
  final isFollowing = await followRepository.isFollowing(currentUser.uid, userId);
  
  if (isFollowing) {
    await followRepository.unfollowUser(currentUser.uid, userId);
  } else {
    await followRepository.followUser(currentUser.uid, userId);
  }
}
```

**개선안:**
```dart
// Repository에서 atomic toggle 제공
Future<FollowAction> toggleFollow(String followerId, String followingId) async {
  final isFollowing = await isFollowing(followerId, followingId);
  
  if (isFollowing) {
    await unfollowUser(followerId, followingId);
    return FollowAction.unfollowed;
  } else {
    await followUser(followerId, followingId);
    return FollowAction.followed;
  }
}

enum FollowAction { followed, unfollowed }
```

---

## 🎨 UI/UX 개선사항

### 8. **프로필 헤더 중복 코드** ⚠️⚠️

**문제:** `profile_screen.dart`와 `user_profile_screen.dart`에 유사한 프로필 헤더

**개선안:**
```dart
// widgets/profile/profile_avatar.dart
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final bool showBadge;
  final VoidCallback? onTap;
  
  const ProfileAvatar({
    this.photoUrl,
    this.radius = 50,
    this.showBadge = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF00C853), width: 3),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF00C853).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Icon(Icons.person, size: radius, color: Color(0xFF9E9E9E))
                : null,
          ),
        ),
        if (showBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildBadge(),
          ),
      ],
    );
  }
}

// widgets/profile/profile_stats_grid.dart
class ProfileStatsGrid extends StatelessWidget {
  final int workoutDays;
  final int totalSquats;
  final int totalLunges;
  final int totalWalkSteps;
  
  // ... 통계 그리드 UI
}
```

---

### 9. **하드코딩된 버전 정보** ⚠️⚠️

**위치:** `profile_screen.dart:541`

```dart
Text('Version 1.0.0', /* ... */),
```

**개선안:**
```dart
// core/config/app_config.dart
class AppConfig {
  static const String appName = 'Military Tracker';
  static const String version = '1.0.2+4';  // pubspec.yaml과 동기화
  static const String buildNumber = '4';
}

// pubspec.yaml에서 자동 생성
// flutter pub run build_runner build
```

---

### 10. **통계 카드 중복** ⚠️⚠️

**문제:** `profile_screen.dart`, `edit_profile_screen.dart`, `user_profile_screen.dart`에 유사한 통계 표시

**개선안:**
```dart
// widgets/profile/workout_stat_card.dart
class WorkoutStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  
  const WorkoutStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(/* ... */),
      ),
    );
  }
}
```

---

## 🚀 확장성 개선

### 11. **프로필 섹션 하드코딩** ⚠️⚠️⚠️

**위치:** `profile_screen.dart:338-437`

**문제:** 메뉴 항목이 하드코딩되어 확장 어려움

**개선안:**
```dart
// models/profile_menu_item.dart
@freezed
class ProfileMenuItem with _$ProfileMenuItem {
  const factory ProfileMenuItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    @Default(false) bool showBadge,
    int? badgeCount,
  }) = _ProfileMenuItem;
}

// core/config/profile_menu_config.dart
class ProfileMenuConfig {
  static List<ProfileMenuSection> getSections(BuildContext context) {
    return [
      ProfileMenuSection(
        title: '활동',
        icon: Icons.local_fire_department_rounded,
        items: [
          ProfileMenuItem(
            id: 'workout_history',
            title: '운동 기록',
            subtitle: 'Workout History',
            icon: Icons.history,
            iconColor: Color(0xFF00C853),
            onTap: () => _navigateToHistory(context),
          ),
          ProfileMenuItem(
            id: 'achievements',
            title: '업적',
            subtitle: 'Achievements',
            icon: Icons.emoji_events_rounded,
            iconColor: Color(0xFFFFD700),
            onTap: () => _navigateToAchievements(context),
          ),
        ],
      ),
      // ... 설정, 계정 섹션
    ];
  }
}

// profile_screen.dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ProfileMenuConfig.getSections(context);
    
    return ListView.separated(
      itemCount: sections.length,
      separatorBuilder: (_, __) => SizedBox(height: 24),
      itemBuilder: (context, index) {
        final section = sections[index];
        return ProfileMenuSection(section: section);
      },
    );
  }
}
```

---

### 12. **통계 데이터 실시간 동기화 부재** ⚠️⚠️⚠️

**문제:** 프로필 화면의 통계가 실시간 업데이트 안 됨

**개선안:**
```dart
// providers/user_stats_provider.dart
final userStatsStreamProvider = StreamProvider.autoDispose<UserStats>((ref) {
  final currentUser = ref.watch(authStateProvider).value;
  if (currentUser == null) return Stream.value(UserStats.empty());
  
  return FirebaseFirestore.instance
    .collection('users')
    .doc(currentUser.uid)
    .snapshots()
    .map((doc) => UserStats.fromFirestore(doc));
});

// profile_screen.dart
final userStats = ref.watch(userStatsStreamProvider);

userStats.when(
  data: (stats) => _buildStatsGrid(stats),
  loading: () => CircularProgressIndicator(),
  error: (_, __) => ErrorWidget(),
);
```

---

### 13. **프로필 캐싱 부재** ⚠️⚠️

**문제:** 매번 네트워크 요청으로 프로필 로드

**개선안:**
```dart
// core/cache/profile_cache_manager.dart
class ProfileCacheManager {
  final Map<String, CachedProfile> _cache = {};
  final Duration _cacheDuration = Duration(minutes: 5);
  
  Future<UserModel?> getProfile(String userId) async {
    // 1. 캐시 확인
    final cached = _cache[userId];
    if (cached != null && !cached.isExpired) {
      logger.d('Profile cache hit: $userId');
      return cached.profile;
    }
    
    // 2. 네트워크 요청
    final profile = await _fetchFromNetwork(userId);
    
    // 3. 캐시 저장
    _cache[userId] = CachedProfile(
      profile: profile,
      timestamp: DateTime.now(),
    );
    
    return profile;
  }
  
  void invalidate(String userId) {
    _cache.remove(userId);
  }
}

class CachedProfile {
  final UserModel profile;
  final DateTime timestamp;
  
  bool get isExpired => DateTime.now().difference(timestamp) > Duration(minutes: 5);
}
```

---

### 14. **팔로워/팔로잉 목록 화면 부재** ⚠️⚠️⚠️

**문제:** 팔로워/팔로잉 숫자만 표시, 클릭 불가

**개선안:**
```dart
// features/profile/presentation/followers_screen.dart
class FollowersScreen extends ConsumerWidget {
  final String userId;
  final FollowListType type;  // followers or following
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followList = type == FollowListType.followers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(type == FollowListType.followers ? '팔로워' : '팔로잉'),
      ),
      body: followList.when(
        data: (userIds) => ListView.builder(
          itemCount: userIds.length,
          itemBuilder: (context, index) {
            final followUser = ref.watch(userProfileProvider(userIds[index]));
            return UserListTile(userAsync: followUser);
          },
        ),
        loading: () => CircularProgressIndicator(),
        error: (_, __) => ErrorWidget(),
      ),
    );
  }
}

// profile_screen.dart에서 사용
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(
          userId: user.id,
          type: FollowListType.followers,
        ),
      ),
    );
  },
  child: _buildFollowStat(/* ... */),
)
```

---

### 15. **프로필 완성도 표시 부재** ⚠️⚠️

**개선안:**
```dart
// models/profile_completeness.dart
class ProfileCompleteness {
  static double calculate(UserModel user) {
    double score = 0.0;
    
    if (user.photoUrl != null) score += 25;  // 프로필 사진
    if (user.bio != null && user.bio!.isNotEmpty) score += 15;  // 자기소개
    if (user.workoutDays > 0) score += 20;  // 운동 기록
    if (user.followerCount > 0 || user.followingCount > 0) score += 15;  // 소셜 활동
    if (user.totalSquats > 100) score += 10;  // 활동성
    if (user.displayName != '게스트') score += 15;  // 닉네임 설정
    
    return score.clamp(0.0, 100.0);
  }
  
  static List<String> getMissingItems(UserModel user) {
    List<String> missing = [];
    
    if (user.photoUrl == null) missing.add('프로필 사진 추가');
    if (user.bio == null || user.bio!.isEmpty) missing.add('자기소개 작성');
    if (user.workoutDays == 0) missing.add('첫 운동 시작');
    
    return missing;
  }
}

// profile_screen.dart에 표시
Widget _buildProfileCompleteness(UserModel user) {
  final completeness = ProfileCompleteness.calculate(user);
  final missing = ProfileCompleteness.getMissingItems(user);
  
  if (completeness >= 100) return SizedBox.shrink();
  
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(/* ... */),
    child: Column(
      children: [
        Row(
          children: [
            Text('프로필 완성도: ${completeness.toInt()}%'),
            Spacer(),
            CircularProgressIndicator(value: completeness / 100),
          ],
        ),
        if (missing.isNotEmpty) ...[
          SizedBox(height: 12),
          ...missing.map((item) => Text('• $item')),
        ],
      ],
    ),
  );
}
```

---

## 📱 모바일 최적화

### 16. **이미지 압축 설정 개선** ⚠️⚠️

**위치:** `edit_profile_screen.dart:134-137`

```dart
final XFile? image = await picker.pickImage(
  source: result,
  maxWidth: 1024,
  maxHeight: 1024,
  imageQuality: 85,
);
```

**개선안:**
```dart
// core/config/image_config.dart
class ImageConfig {
  static const int profileMaxWidth = 512;
  static const int profileMaxHeight = 512;
  static const int profileQuality = 80;
  
  static const int postMaxWidth = 1920;
  static const int postMaxHeight = 1920;
  static const int postQuality = 85;
}

// 사용
final XFile? image = await picker.pickImage(
  source: result,
  maxWidth: ImageConfig.profileMaxWidth,
  maxHeight: ImageConfig.profileMaxHeight,
  imageQuality: ImageConfig.profileQuality,
);
```

---

### 17. **Pull-to-Refresh 부재** ⚠️⚠️

**개선안:**
```dart
// profile_screen.dart
body: RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(currentUserProvider);
    await Future.delayed(Duration(milliseconds: 500));
  },
  child: SingleChildScrollView(/* ... */),
)
```

---

## 🔒 보안 개선

### 18. **프로필 편집 권한 체크 부족** ⚠️⚠️⚠️

**위치:** `edit_profile_screen.dart`

**문제:** 다른 사용자의 프로필을 URL로 직접 접근하여 편집 시도 가능

**개선안:**
```dart
// edit_profile_screen.dart
class EditProfileScreen extends ConsumerStatefulWidget {
  final String? userId;  // null이면 본인 프로필
  
  const EditProfileScreen({this.userId});
  
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }
  
  void _checkPermission() {
    final currentUser = ref.read(authStateProvider).value;
    final targetUserId = widget.userId ?? currentUser?.uid;
    
    // 본인이 아니면 접근 차단
    if (currentUser == null || currentUser.uid != targetUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        AppSnackBar.showError(context, '권한이 없습니다');
      });
    }
  }
}
```

---

## 📊 개선 우선순위

### 🔴 높음 (즉시)
1. Result 패턴 적용 (profile_screen, edit_profile_screen)
2. print → logger 변경
3. Unused import 제거
4. AppSnackBar 사용

### 🟡 중간 (1주 내)
5. 사용자 모델 통합
6. 프로필 이미지 서비스 분리
7. 공통 UI 컴포넌트 추출
8. 팔로워/팔로잉 목록 화면
9. 프로필 캐싱

### 🟢 낮음 (장기)
10. 프로필 완성도 표시
11. 실시간 통계 동기화
12. Pull-to-Refresh
13. 이미지 최적화 설정 통합

---

## 📈 예상 개선 효과

| 항목 | 현재 | 개선 후 | 효과 |
|------|------|---------|------|
| **코드 품질** | 7.5/10 | 9.0/10 | +20% |
| **유지보수성** | 6.5/10 | 8.5/10 | +31% |
| **확장성** | 6.0/10 | 8.5/10 | +42% |
| **사용자 경험** | 7.0/10 | 8.5/10 | +21% |
| **보안** | 7.5/10 | 9.0/10 | +20% |

---

## 🎯 다음 단계

1. **즉시 수정** (1-2시간)
   - Result 패턴 적용
   - print → logger
   - AppSnackBar 통합

2. **단기 개선** (1주)
   - UI 컴포넌트 분리
   - 팔로워/팔로잉 화면
   - 프로필 캐싱

3. **중장기 개선** (1개월)
   - 프로필 완성도
   - 실시간 동기화
   - 고급 기능 (배지, 등급 등)

---

**총 발견된 이슈: 18개**  
**치명적: 1개 | 심각: 3개 | 중간: 14개**

