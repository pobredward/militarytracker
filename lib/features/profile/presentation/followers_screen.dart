import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/follow_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_profile_model.dart';
import '../widgets/profile_widgets.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends ConsumerWidget {
  final String userId;

  const FollowersScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'FOLLOWERS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: followersAsync.when(
        data: (followerIds) {
          if (followerIds.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: '팔로워가 없습니다',
              subtitle: '아직 팔로워가 없습니다',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: followerIds.length,
            itemBuilder: (context, index) {
              final followerId = followerIds[index];
              return _FollowerListItem(
                userId: followerId,
                currentUserId: userId,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C853),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFCF6679),
              ),
              const SizedBox(height: 16),
              Text(
                '팔로워 목록을 불러올 수 없습니다',
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowingScreen extends ConsumerWidget {
  final String userId;

  const FollowingScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'FOLLOWING',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: followingAsync.when(
        data: (followingIds) {
          if (followingIds.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.person_add_outlined,
              title: '팔로잉이 없습니다',
              subtitle: '다른 사용자를 팔로우해보세요',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: followingIds.length,
            itemBuilder: (context, index) {
              final followingId = followingIds[index];
              return _FollowerListItem(
                userId: followingId,
                currentUserId: userId,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C853),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFCF6679),
              ),
              const SizedBox(height: 16),
              Text(
                '팔로잉 목록을 불러올 수 없습니다',
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 팔로워/팔로잉 목록 아이템
class _FollowerListItem extends ConsumerWidget {
  final String userId;
  final String currentUserId;

  const _FollowerListItem({
    required this.userId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUser = ref.watch(authStateProvider).value;
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));

    return profileAsync.when(
      data: (profile) {
        final isCurrentUser = currentUser?.uid == userId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2A2A2A),
            ),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: userId),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00C853),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: profile.photoURL != null
                    ? NetworkImage(profile.photoURL!)
                    : null,
                child: profile.photoURL == null
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF9E9E9E),
                        size: 28,
                      )
                    : null,
              ),
            ),
            title: Text(
              profile.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE0E0E0),
              ),
            ),
            subtitle: profile.bio != null && profile.bio!.isNotEmpty
                ? Text(
                    profile.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  )
                : null,
            trailing: isCurrentUser
                ? null
                : isFollowingAsync.when(
                    data: (isFollowing) {
                      return SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(followNotifierProvider.notifier)
                                .toggleFollow(userId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFF00C853),
                            foregroundColor: isFollowing
                                ? const Color(0xFF00C853)
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isFollowing
                                  ? const BorderSide(
                                      color: Color(0xFF00C853),
                                      width: 1.5,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            isFollowing ? '팔로잉' : '팔로우',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 100,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00C853),
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A2A2A),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00C853),
            ),
          ),
        ),
      ),
      error: (error, stack) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFCF6679),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFCF6679),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '사용자 정보를 불러올 수 없습니다',
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
