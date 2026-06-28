import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_snackbar.dart';
import 'workout_history_screen.dart';
import 'edit_profile_screen.dart';
import 'achievements_screen.dart';
import 'notification_settings_screen.dart';
import 'help_screen.dart';
import 'statistics_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final authActions = ref.read(authActionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFCF6679)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text(
                    '로그아웃',
                    style: TextStyle(color: Color(0xFFE0E0E0)),
                  ),
                  content: const Text(
                    '정말 로그아웃하시겠습니까?',
                    style: TextStyle(color: Color(0xFF9E9E9E)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCF6679),
                      ),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final result = await authActions.signOut();
                result.when(
                  success: (_) {
                    // 로그아웃 성공 (자동으로 AuthGate가 로그인 화면으로 전환)
                  },
                  failure: (message, _) {
                    if (context.mounted) {
                      AppSnackBar.showError(context, message);
                    }
                  },
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: currentUserAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('사용자 정보를 불러올 수 없습니다'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 프로필 헤더
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00C853).withOpacity(0.15),
                          const Color(0xFF00C853).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00C853).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00C853),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C853).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF1E1E1E),
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFF9E9E9E),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF121212),
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 팔로워/팔로잉 통계
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFollowStat(
                              context,
                              '팔로워',
                              user.followerCount,
                              Icons.people_outline,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              color: const Color(0xFF2A2A2A),
                            ),
                            _buildFollowStat(
                              context,
                              '팔로잉',
                              user.followingCount,
                              Icons.person_add_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.authProvider == 'google' 
                                    ? Icons.g_mobiledata_rounded
                                    : Icons.email_outlined,
                                size: 18,
                                color: const Color(0xFF00C853),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.authProvider == 'google' ? 'Google 로그인' : '이메일 로그인',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 전체 운동 통계
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF00C853),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '운동 통계',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                '운동일',
                                '${user.workoutDays}',
                                '일',
                                Icons.calendar_today,
                                const Color(0xFF00C853),
                              ),
                              _buildStatItem(
                                '스쿼트',
                                '${user.totalSquats}',
                                '회',
                                Icons.accessibility_new,
                                const Color(0xFF2196F3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                '런지',
                                '${user.totalLunges}',
                                '회',
                                Icons.directions_run,
                                const Color(0xFF9C27B0),
                              ),
                              _buildStatItem(
                                '걷기',
                                '${user.totalWalkSteps}',
                                '보',
                                Icons.directions_walk,
                                const Color(0xFFFF9800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 메뉴 목록
                  _buildSectionHeader('활동', Icons.local_fire_department_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.history,
                          iconColor: const Color(0xFF00C853),
                          title: '운동 기록',
                          subtitle: 'Workout History',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const WorkoutHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF2A2A2A)),
                        _buildMenuItem(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFFFD700),
                          title: '업적',
                          subtitle: 'Achievements',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AchievementsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 설정 섹션
                  _buildSectionHeader('설정', Icons.settings_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF2196F3),
                          title: '프로필 수정',
                          subtitle: 'Edit Profile',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF2A2A2A)),
                        _buildMenuItem(
                          icon: Icons.notifications_rounded,
                          iconColor: const Color(0xFFFF9800),
                          title: '알림 설정',
                          subtitle: 'Notifications',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF2A2A2A)),
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFF9C27B0),
                          title: '도움말',
                          subtitle: 'Help & FAQ',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const HelpScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 계정 관리
                  _buildSectionHeader('계정', Icons.security_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          iconColor: const Color(0xFFCF6679),
                          title: '계정 삭제',
                          subtitle: 'Delete Account',
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text(
                                  '계정 삭제',
                                  style: TextStyle(color: Color(0xFFE0E0E0)),
                                ),
                                content: const Text(
                                  '정말 계정을 삭제하시겠습니까?\n모든 데이터가 영구적으로 삭제됩니다.',
                                  style: TextStyle(color: Color(0xFF9E9E9E)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFCF6679),
                                    ),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              final result = await authActions.deleteAccount();
                              result.when(
                                success: (_) {
                                  // 계정 삭제 성공 (자동으로 로그아웃)
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
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 앱 정보
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF00E676)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MILITARY TRACKER',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00C853),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          color: const Color(0xFF9E9E9E),
                          onPressed: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Military Tracker',
                              applicationVersion: '1.0.0',
                              applicationIcon: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('오류가 발생했습니다: $error'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00C853), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF616161),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE0E0E0),
                ),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowStat(
    BuildContext context,
    String label,
    int count,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF00C853),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE0E0E0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
