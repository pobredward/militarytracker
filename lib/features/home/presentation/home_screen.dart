import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/constants.dart';
import '../../../core/config/scoring_config.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../profile/presentation/workout_history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayWorkout = ref.watch(todayWorkoutProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 커스텀 앱바
            SliverAppBar(
              backgroundColor: const Color(0xFF121212),
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF121212).withOpacity(0),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                    children: [
                      Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF00C853).withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.military_tech_rounded,
                                    color: Color(0xFF00C853),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'MILITARY TRACKER',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      fontSize: 12,
                          color: Color(0xFF00C853),
                        ),
                      ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF2A2A2A)),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF9E9E9E),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        currentUser.when(
                          data: (user) => Text(
                            '${DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9E9E9E),
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 환영 메시지 & 오늘의 달성률
                    currentUser.when(
                      data: (user) => _buildWelcomeCard(user?.displayName),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 24),
                    
                    // 오늘의 목표 달성 요약
                    todayWorkout.when(
                      data: (workout) {
                        final squat = workout?.squatCount ?? 0;
                        final lunge = workout?.lungeCount ?? 0;
                        final walk = workout?.walkSteps ?? 0;
                        final run = workout?.runDistance ?? 0.0;
                        
                        // ScoringConfig를 사용한 진행률 계산
                        final squatProgress = ScoringConfig.calculateSquatProgress(squat, AppConstants.squatGoal);
                        final lungeProgress = ScoringConfig.calculateLungeProgress(lunge, AppConstants.lungeGoal);
                        final walkProgress = ScoringConfig.calculateWalkProgress(walk, AppConstants.walkGoal);
                        final runProgress = ScoringConfig.calculateRunProgress(run, AppConstants.runGoal);
                        
                        final totalProgress = (squatProgress + lungeProgress + walkProgress + runProgress) / 4;
                        
                        return _buildTodaySummaryCard(totalProgress);
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 32),
                    
                    // 주간 진행 현황
                    _buildSectionHeader('WEEKLY PROGRESS', '이번 주 진행 현황'),
                    const SizedBox(height: 20),
                    _buildWeeklyProgressChart(),
              const SizedBox(height: 32),
              
              // 빠른 액션
                    _buildSectionHeader('QUICK ACTIONS', '빠른 액세스'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            icon: Icons.play_circle_fill_rounded,
                            title: '운동 시작',
                            subtitle: 'Start Workout',
                            color: const Color(0xFF00C853),
                            onTap: () {
                              // Navigate to workout screen (tab index 2)
                              ref.read(navigationIndexProvider.notifier).state = 2;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            icon: Icons.timeline_rounded,
                            title: '기록 보기',
                            subtitle: 'View History',
                            color: const Color(0xFF2196F3),
                            onTap: () {
                              // Navigate to workout history screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const WorkoutHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            icon: Icons.leaderboard_rounded,
                            title: '순위표',
                            subtitle: 'Leaderboard',
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              // Navigate to ranking screen
                              ref.read(navigationIndexProvider.notifier).state = 3;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            icon: Icons.settings_rounded,
                            title: '설정',
                            subtitle: 'Settings',
                            color: const Color(0xFF9E9E9E),
                            onTap: () {
                              // Navigate to profile screen (settings section)
                              ref.read(navigationIndexProvider.notifier).state = 4;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 환영 카드
  Widget _buildWelcomeCard(String? userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C853).withOpacity(0.2),
                  const Color(0xFF00C853).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 32,
              color: Color(0xFF00C853),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '환영합니다, ${userName ?? '사용자'}님!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '오늘도 목표를 향해 전진하세요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 오늘의 달성률 요약 카드
  Widget _buildTodaySummaryCard(double totalProgress) {
    final percentage = (totalProgress * 100).clamp(0, 100).toInt();
    String motivationMessage;
    IconData motivationIcon;
    
    if (percentage >= 100) {
      motivationMessage = '완벽합니다! 목표 달성! 🎉';
      motivationIcon = Icons.workspace_premium_rounded;
    } else if (percentage >= 75) {
      motivationMessage = '거의 다 왔어요! 조금만 더!';
      motivationIcon = Icons.trending_up_rounded;
    } else if (percentage >= 50) {
      motivationMessage = '절반을 넘었어요! 화이팅!';
      motivationIcon = Icons.local_fire_department_rounded;
    } else if (percentage >= 25) {
      motivationMessage = '좋은 시작이에요! 계속 진행하세요!';
      motivationIcon = Icons.rocket_launch_rounded;
    } else {
      motivationMessage = '오늘의 목표를 시작해보세요!';
      motivationIcon = Icons.flag_rounded;
    }

    return FadeTransition(
      opacity: _animationController,
      child: Container(
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
            Row(
              children: [
                Icon(
                  motivationIcon,
                  color: const Color(0xFF00C853),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘의 전체 달성률',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        motivationMessage,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00C853),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(
                  begin: 0,
                  end: totalProgress.clamp(0.0, 1.0),
                ),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 섹션 헤더
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00E676)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE0E0E0),
                      letterSpacing: 1.5,
                    ),
                  ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF616161),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 주간 진행 현황 차트
  Widget _buildWeeklyProgressChart() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weeklyWorkouts = ref.watch(weeklyWorkoutProvider);

    return weeklyWorkouts.when(
      data: (workouts) {
        // ScoringConfig를 사용한 진행률 계산
        final goals = {
          'squat': AppConstants.squatGoal,
          'lunge': AppConstants.lungeGoal,
          'walk': AppConstants.walkGoal,
          'run': AppConstants.runGoal,
        };
        
        final weeklyProgress = workouts.map((workout) {
          if (workout == null) return 0.0;
          return ScoringConfig.calculateTotalProgress(workout, goals);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  final progress = weeklyProgress[index];
                  final isToday = index == now.weekday - 1;
                  
                  return Column(
                    children: [
                      Container(
                        width: 36,
                        height: 100,
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: progress.clamp(0.0, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isToday ? const Color(0xFF00C853) : const Color(0xFF424242),
                                  isToday ? const Color(0xFF00E676) : const Color(0xFF616161),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weekdays[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? const Color(0xFF00C853) : const Color(0xFF9E9E9E),
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C853),
          ),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Center(
          child: Text(
            '데이터를 불러올 수 없습니다',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
