import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile_model.dart';
import '../../../providers/follow_provider.dart';
import '../../../providers/auth_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider(widget.userId));
    final currentUser = ref.watch(authStateProvider).value;
    final isOwnProfile = currentUser?.uid == widget.userId;

    return Scaffold(
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('프로필을 불러올 수 없습니다\n$error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('뒤로 가기'),
              ),
            ],
          ),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            _buildAppBar(context, profile, isOwnProfile),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildProfileHeader(profile, isOwnProfile),
                  const Divider(height: 1),
                  _buildStatsSection(profile),
                  const Divider(height: 1),
                  _buildTabBar(),
                ],
              ),
            ),
            _buildTabContent(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, UserProfileModel profile, bool isOwnProfile) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Hero(
              tag: 'user_avatar_${profile.userId}',
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profile.photoURL != null
                    ? NetworkImage(profile.photoURL!)
                    : null,
                child: profile.photoURL == null
                    ? Text(
                        profile.displayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfileModel profile, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            profile.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFollowButton(profile.userId, profile.isFollowing, isOwnProfile),
              if (!isOwnProfile) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 메시지 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('메시지 기능은 준비 중입니다')),
                    );
                  },
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('메시지'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(String userId, bool isFollowing, bool isOwnProfile) {
    if (isOwnProfile) {
      return OutlinedButton.icon(
        onPressed: () {
          // TODO: 프로필 편집 기능
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필 편집 기능은 준비 중입니다')),
          );
        },
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('프로필 편집'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    }

    // 팔로우 액션 상태를 watch
    final followState = ref.watch(followNotifierProvider);
    final isLoading = followState.isLoading;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : () async {
        try {
          await ref.read(followNotifierProvider.notifier).toggleFollow(userId);
          // 프로필 정보 즉시 갱신
          ref.invalidate(userProfileProvider(widget.userId));
        } catch (e) {
          if (mounted) {
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
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isFollowing ? Icons.person_remove : Icons.person_add,
              size: 18,
            ),
      label: Text(isFollowing ? '팔로잉' : '팔로우'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey[300] : null,
        foregroundColor: isFollowing ? Colors.black87 : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildStatsSection(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('게시글', '0'), // TODO: 실제 게시글 수
          _buildStatItem('팔로워', profile.followerCount.toString()),
          _buildStatItem('팔로잉', profile.followingCount.toString()),
          _buildStatItem('운동일', profile.totalWorkoutDays.toString()),
          if (profile.streak > 0)
            _buildStatItem('🔥 연속', '${profile.streak}일'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: '운동 통계'),
          Tab(text: '게시글'),
        ],
      ),
    );
  }

  Widget _buildTabContent(UserProfileModel profile) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutStats(profile),
          _buildUserPosts(),
        ],
      ),
    );
  }

  Widget _buildWorkoutStats(UserProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '총 운동량',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWorkoutStatCard(
            '스쿼트',
            profile.totalSquats.toString(),
            '회',
            Icons.fitness_center,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildWorkoutStatCard(
            '런지',
            profile.totalLunges.toString(),
            '회',
            Icons.directions_walk,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildWorkoutStatCard(
            '걷기',
            profile.totalWalkSteps.toString(),
            '걸음',
            Icons.directions_walk_outlined,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildWorkoutStatCard(
            '뛰기',
            profile.totalRunDistance.toStringAsFixed(2),
            'km',
            Icons.directions_run,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPosts() {
    final userPostsAsync = ref.watch(userPostsProvider(widget.userId));

    return userPostsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('게시글을 불러올 수 없습니다\n$error'),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '아직 작성된 게시글이 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final post = posts[index];
            // 간단한 게시글 미리보기
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              title: Text(
                post['content'] as String? ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _formatTimestamp(post['createdAt']),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                // TODO: 게시글 상세 화면으로 이동
              },
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final DateTime dateTime = timestamp is DateTime 
        ? timestamp 
        : timestamp.toDate();
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
