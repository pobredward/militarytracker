import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/presentation/user_profile_screen.dart';
import '../models/user_profile_model.dart';
import '../providers/follow_provider.dart';
import '../providers/auth_provider.dart';

/// 사용자 정보를 간단히 표시하는 카드 위젯
/// 랭킹, 커뮤니티 등에서 사용
class UserCard extends ConsumerWidget {
  final String userId;
  final String displayName;
  final String? photoURL;
  final Widget? trailing; // 오른쪽에 표시할 위젯 (예: 순위, 점수 등)
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.userId,
    required this.displayName,
    this.photoURL,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap ??
          () {
            // 바로 프로필 페이지로 이동 (모달 없이)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(userId: userId),
              ),
            );
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Hero(
              tag: 'user_avatar_$userId',
              child: CircleAvatar(
                radius: 24,
                backgroundImage:
                    photoURL != null ? NetworkImage(photoURL!) : null,
                backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
                child: photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C853),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE0E0E0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// 상세한 사용자 정보 카드 (바텀시트나 다이얼로그에서 사용)
class UserDetailCard extends ConsumerWidget {
  final String userId;

  const UserDetailCard({
    super.key,
    required this.userId,
  });

  static Future<void> show(BuildContext context, String userId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailCard(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(userId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: userProfileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('프로필을 불러올 수 없습니다\n$error',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (profile) => _buildContent(context, ref, profile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UserProfileModel profile) {
    final currentUser = ref.watch(authStateProvider).value;
    final isOwnProfile = currentUser?.uid == userId;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 프로필 이미지
            Hero(
              tag: 'user_avatar_${profile.userId}',
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profile.photoURL != null
                    ? NetworkImage(profile.photoURL!)
                    : null,
                child: profile.photoURL == null
                    ? Text(
                        profile.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // 이름
            Text(
              profile.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 자기소개
            if (profile.bio != null) ...[
              const SizedBox(height: 8),
              Text(
                profile.bio!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            // 통계 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('팔로워', profile.followerCount.toString()),
                _buildStatColumn('팔로잉', profile.followingCount.toString()),
                _buildStatColumn('운동일', profile.totalWorkoutDays.toString()),
                if (profile.streak > 0)
                  _buildStatColumn('🔥 연속', '${profile.streak}일'),
              ],
            ),
            const SizedBox(height: 24),
            // 간단한 운동 통계
            _buildQuickStats(profile),
            const SizedBox(height: 24),
            // 액션 버튼
            Row(
              children: [
                if (!isOwnProfile) ...[
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final followState = ref.watch(followNotifierProvider);
                        final isLoading = followState.isLoading;

                        return ElevatedButton.icon(
                          onPressed: isLoading ? null : () async {
                            try {
                              await ref
                                  .read(followNotifierProvider.notifier)
                                  .toggleFollow(userId);
                              // 프로필 정보 즉시 갱신
                              ref.invalidate(userProfileProvider(userId));
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('오류가 발생했습니다: $e')),
                                );
                              }
                            }
                          },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  profile.isFollowing
                                      ? Icons.person_remove
                                      : Icons.person_add,
                                  size: 18,
                                ),
                          label: Text(profile.isFollowing ? '팔로잉' : '팔로우'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                profile.isFollowing ? Colors.grey[300] : null,
                            foregroundColor:
                                profile.isFollowing ? Colors.black87 : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(userId: userId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outlined, size: 18),
                    label: const Text('프로필 보기'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 통계',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickStatItem(
                Icons.fitness_center,
                '스쿼트',
                profile.totalSquats.toString(),
                Colors.blue,
              ),
              _buildQuickStatItem(
                Icons.directions_walk,
                '런지',
                profile.totalLunges.toString(),
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickStatItem(
                Icons.directions_walk_outlined,
                '걷기',
                '${profile.totalWalkSteps} 걸음',
                Colors.orange,
              ),
              _buildQuickStatItem(
                Icons.directions_run,
                '뛰기',
                '${profile.totalRunDistance.toStringAsFixed(1)} km',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
