import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../repositories/follow_repository.dart';
import '../core/config/logger.dart';
import 'auth_provider.dart';

// FollowRepository 인스턴스
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

// 특정 사용자 프로필 정보
final userProfileProvider =
    FutureProvider.family<UserProfileModel, String>((ref, userId) async {
  final followRepository = ref.watch(followRepositoryProvider);
  final currentUser = ref.watch(authStateProvider).value;

  if (currentUser == null) {
    throw Exception('로그인이 필요합니다.');
  }

  return await followRepository.getUserProfile(userId, currentUser.uid);
});

// 팔로우 상태
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final followRepository = ref.watch(followRepositoryProvider);
  final currentUser = ref.watch(authStateProvider).value;

  if (currentUser == null) {
    return false;
  }

  return await followRepository.isFollowing(currentUser.uid, userId);
});

// 팔로워 목록
final followersProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  final followRepository = ref.watch(followRepositoryProvider);
  return followRepository.getFollowers(userId);
});

// 팔로잉 목록
final followingProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  final followRepository = ref.watch(followRepositoryProvider);
  return followRepository.getFollowing(userId);
});

// 팔로워 수
final followerCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final followRepository = ref.watch(followRepositoryProvider);
  return await followRepository.getFollowerCount(userId);
});

// 팔로잉 수
final followingCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final followRepository = ref.watch(followRepositoryProvider);
  return await followRepository.getFollowingCount(userId);
});

// 사용자의 최근 게시글
final userPostsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final followRepository = ref.watch(followRepositoryProvider);
  return followRepository.getUserPosts(userId);
});

// 팔로우/언팔로우 액션
class FollowNotifier extends StateNotifier<AsyncValue<void>> {
  FollowNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> toggleFollow(String userId) async {
    state = const AsyncValue.loading();

    try {
      final followRepository = ref.read(followRepositoryProvider);
      final currentUser = ref.read(authStateProvider).value;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 최신 팔로우 상태를 다시 확인
      final isFollowing =
          await followRepository.isFollowing(currentUser.uid, userId);

      AppLogger.d('Toggle Follow - userId: $userId, currentFollowing: $isFollowing');

      if (isFollowing) {
        AppLogger.d('Unfollowing user: $userId');
        await followRepository.unfollowUser(currentUser.uid, userId);
      } else {
        AppLogger.d('Following user: $userId');
        await followRepository.followUser(currentUser.uid, userId);
      }

      // 프로필 정보 갱신
      ref.invalidate(userProfileProvider(userId));
      ref.invalidate(isFollowingProvider(userId));
      // 팔로워/팔로잉 카운트도 갱신
      ref.invalidate(followerCountProvider(userId));
      ref.invalidate(followingCountProvider(userId));

      state = const AsyncValue.data(null);
      
      AppLogger.d('Toggle Follow completed successfully');
    } catch (e, stack) {
      AppLogger.e('Toggle Follow error: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final followNotifierProvider =
    StateNotifierProvider<FollowNotifier, AsyncValue<void>>((ref) {
  return FollowNotifier(ref);
});
