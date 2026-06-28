import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/statistics_provider.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredValue;
  final String category; // 'workout', 'streak', 'special'
  final Color color;
  
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.category,
    required this.color,
  });
}

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Achievement> _achievements = [
    // 운동 관련 업적
    const Achievement(
      id: 'squat_beginner',
      title: '스쿼트 입문자',
      description: '스쿼트 100회 달성',
      icon: Icons.accessibility_new_rounded,
      requiredValue: 100,
      category: 'workout',
      color: Color(0xFF00C853),
    ),
    const Achievement(
      id: 'squat_intermediate',
      title: '스쿼트 중수',
      description: '스쿼트 500회 달성',
      icon: Icons.accessibility_new_rounded,
      requiredValue: 500,
      category: 'workout',
      color: Color(0xFF00C853),
    ),
    const Achievement(
      id: 'squat_master',
      title: '스쿼트 마스터',
      description: '스쿼트 1,000회 달성',
      icon: Icons.accessibility_new_rounded,
      requiredValue: 1000,
      category: 'workout',
      color: Color(0xFFFFD700),
    ),
    const Achievement(
      id: 'lunge_beginner',
      title: '런지 입문자',
      description: '런지 100회 달성',
      icon: Icons.directions_run_rounded,
      requiredValue: 100,
      category: 'workout',
      color: Color(0xFF2196F3),
    ),
    const Achievement(
      id: 'lunge_intermediate',
      title: '런지 중수',
      description: '런지 500회 달성',
      icon: Icons.directions_run_rounded,
      requiredValue: 500,
      category: 'workout',
      color: Color(0xFF2196F3),
    ),
    const Achievement(
      id: 'lunge_master',
      title: '런지 마스터',
      description: '런지 1,000회 달성',
      icon: Icons.directions_run_rounded,
      requiredValue: 1000,
      category: 'workout',
      color: Color(0xFFFFD700),
    ),
    const Achievement(
      id: 'walker',
      title: '워커',
      description: '10,000보 걷기 달성',
      icon: Icons.directions_walk_rounded,
      requiredValue: 10000,
      category: 'workout',
      color: Color(0xFF9C27B0),
    ),
    const Achievement(
      id: 'runner',
      title: '러너',
      description: '5km 뛰기 달성',
      icon: Icons.run_circle_rounded,
      requiredValue: 5,
      category: 'workout',
      color: Color(0xFFFF5722),
    ),
    
    // 연속 운동 업적
    const Achievement(
      id: 'streak_3',
      title: '3일 연속',
      description: '3일 연속 운동',
      icon: Icons.local_fire_department_rounded,
      requiredValue: 3,
      category: 'streak',
      color: Color(0xFFFF9800),
    ),
    const Achievement(
      id: 'streak_7',
      title: '일주일 전사',
      description: '7일 연속 운동',
      icon: Icons.local_fire_department_rounded,
      requiredValue: 7,
      category: 'streak',
      color: Color(0xFFFF9800),
    ),
    const Achievement(
      id: 'streak_30',
      title: '한 달 챌린지',
      description: '30일 연속 운동',
      icon: Icons.local_fire_department_rounded,
      requiredValue: 30,
      category: 'streak',
      color: Color(0xFFFFD700),
    ),
    
    // 특별 업적
    const Achievement(
      id: 'first_workout',
      title: '첫 걸음',
      description: '첫 운동 완료',
      icon: Icons.celebration_rounded,
      requiredValue: 1,
      category: 'special',
      color: Color(0xFF00C853),
    ),
    const Achievement(
      id: 'perfectionist',
      title: '완벽주의자',
      description: '하루 모든 목표 100% 달성',
      icon: Icons.workspace_premium_rounded,
      requiredValue: 1,
      category: 'special',
      color: Color(0xFFFFD700),
    ),
    const Achievement(
      id: 'early_bird',
      title: '얼리버드',
      description: '오전 6시 이전 운동 10회',
      icon: Icons.wb_sunny_rounded,
      requiredValue: 10,
      category: 'special',
      color: Color(0xFFFFA726),
    ),
    const Achievement(
      id: 'night_owl',
      title: '야행성',
      description: '밤 10시 이후 운동 10회',
      icon: Icons.nights_stay_rounded,
      requiredValue: 10,
      category: 'special',
      color: Color(0xFF5E35B1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realTimeStats = ref.watch(realTimeStatsProvider);
    final currentStreak = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'ACHIEVEMENTS',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00C853),
          labelColor: const Color(0xFF00C853),
          unselectedLabelColor: const Color(0xFF616161),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '운동'),
            Tab(text: '연속'),
            Tab(text: '특별'),
          ],
        ),
      ),
      body: SafeArea(
        child: realTimeStats.when(
          data: (stats) {
            final totalSquats = stats['totalSquats'] as int;
            final totalLunges = stats['totalLunges'] as int;
            final totalWalkSteps = stats['totalWalkSteps'] as int;
            final totalRunDistance = stats['totalRunDistance'] as double;
            final workoutDays = stats['workoutDays'] as int;
            
            return currentStreak.when(
              data: (streak) {
                return Column(
                  children: [
                    // 업적 요약
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00C853).withOpacity(0.15),
                            const Color(0xFF00C853).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00C853).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            icon: Icons.emoji_events_rounded,
                            label: '획득한 업적',
                            value: _getUnlockedCount(totalSquats, totalLunges, totalWalkSteps, totalRunDistance, workoutDays, streak),
                            total: _achievements.length,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFF2A2A2A),
                          ),
                          _buildSummaryItem(
                            icon: Icons.workspace_premium_rounded,
                            label: '완료율',
                            value: _getCompletionPercentage(totalSquats, totalLunges, totalWalkSteps, totalRunDistance, workoutDays, streak),
                            isPercentage: true,
                          ),
                        ],
                      ),
                    ),

                    // 업적 목록
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAchievementList(_achievements, totalSquats, totalLunges, totalWalkSteps, totalRunDistance, workoutDays, streak),
                          _buildAchievementList(
                            _achievements.where((a) => a.category == 'workout').toList(),
                            totalSquats, totalLunges, totalWalkSteps, totalRunDistance, workoutDays, streak,
                          ),
                          _buildAchievementList(
                            _achievements.where((a) => a.category == 'streak').toList(),
                            totalSquats, totalLunges, totalWalkSteps, totalRunDistance, workoutDays, streak,
                          ),
                          _buildAchievementList(
                            _achievements.where((a) => a.category == 'special').toList(),
                            totalSquats, totalLunges, totalWalkSteps, totalRunDistance, workoutDays, streak,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C853)),
              ),
              error: (_, __) => const Center(
                child: Text(
                  '데이터를 불러올 수 없습니다',
                  style: TextStyle(color: Color(0xFFCF6679)),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00C853)),
          ),
          error: (_, __) => const Center(
            child: Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(color: Color(0xFFCF6679)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required int value,
    int? total,
    bool isPercentage = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00C853), size: 32),
        const SizedBox(height: 8),
        if (isPercentage)
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE0E0E0),
            ),
          )
        else
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                if (total != null)
                  TextSpan(
                    text: ' / $total',
                    style: const TextStyle(
                      fontSize: 16,
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
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementList(
    List<Achievement> achievements,
    int totalSquats,
    int totalLunges,
    int totalWalkSteps,
    double totalRunDistance,
    int workoutDays,
    int currentStreak,
  ) {
    if (achievements.isEmpty) {
      return const Center(
        child: Text(
          '업적이 없습니다',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = _isAchievementUnlocked(
          achievement,
          totalSquats,
          totalLunges,
          totalWalkSteps,
          totalRunDistance,
          workoutDays,
          currentStreak,
        );
        final progress = _getAchievementProgress(
          achievement,
          totalSquats,
          totalLunges,
          totalWalkSteps,
          totalRunDistance,
          workoutDays,
          currentStreak,
        );

        return _buildAchievementCard(achievement, isUnlocked, progress);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? achievement.color.withOpacity(0.1)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked 
              ? achievement.color.withOpacity(0.5)
              : const Color(0xFF2A2A2A),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: achievement.color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [
                        achievement.color,
                        achievement.color.withOpacity(0.7),
                      ],
                    )
                  : null,
              color: isUnlocked ? null : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked ? Colors.black : const Color(0xFF616161),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked 
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: achievement.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '획득',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnlocked 
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF616161),
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF2A2A2A),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        achievement.color.withOpacity(0.7),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toInt()}% 완료',
                    style: TextStyle(
                      fontSize: 11,
                      color: achievement.color.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isAchievementUnlocked(
    Achievement achievement,
    int totalSquats,
    int totalLunges,
    int totalWalkSteps,
    double totalRunDistance,
    int workoutDays,
    int currentStreak,
  ) {
    switch (achievement.id) {
      case 'squat_beginner':
      case 'squat_intermediate':
      case 'squat_master':
        return totalSquats >= achievement.requiredValue;
      case 'lunge_beginner':
      case 'lunge_intermediate':
      case 'lunge_master':
        return totalLunges >= achievement.requiredValue;
      case 'walker':
        return totalWalkSteps >= achievement.requiredValue;
      case 'runner':
        return totalRunDistance >= achievement.requiredValue;
      case 'first_workout':
        return workoutDays >= 1;
      case 'streak_3':
      case 'streak_7':
      case 'streak_30':
        return currentStreak >= achievement.requiredValue;
      default:
        return false; // 특별 업적은 아직 구현 안됨
    }
  }

  double _getAchievementProgress(
    Achievement achievement,
    int totalSquats,
    int totalLunges,
    int totalWalkSteps,
    double totalRunDistance,
    int workoutDays,
    int currentStreak,
  ) {
    double current = 0;
    switch (achievement.id) {
      case 'squat_beginner':
      case 'squat_intermediate':
      case 'squat_master':
        current = totalSquats.toDouble();
        break;
      case 'lunge_beginner':
      case 'lunge_intermediate':
      case 'lunge_master':
        current = totalLunges.toDouble();
        break;
      case 'walker':
        current = totalWalkSteps.toDouble();
        break;
      case 'runner':
        current = totalRunDistance;
        break;
      case 'first_workout':
        current = workoutDays.toDouble();
        break;
      case 'streak_3':
      case 'streak_7':
      case 'streak_30':
        current = currentStreak.toDouble();
        break;
      default:
        current = 0;
    }
    return (current / achievement.requiredValue).clamp(0.0, 1.0);
  }

  int _getUnlockedCount(
    int totalSquats,
    int totalLunges,
    int totalWalkSteps,
    double totalRunDistance,
    int workoutDays,
    int currentStreak,
  ) {
    return _achievements.where((a) => _isAchievementUnlocked(
      a,
      totalSquats,
      totalLunges,
      totalWalkSteps,
      totalRunDistance,
      workoutDays,
      currentStreak,
    )).length;
  }

  int _getCompletionPercentage(
    int totalSquats,
    int totalLunges,
    int totalWalkSteps,
    double totalRunDistance,
    int workoutDays,
    int currentStreak,
  ) {
    final unlockedCount = _getUnlockedCount(
      totalSquats,
      totalLunges,
      totalWalkSteps,
      totalRunDistance,
      workoutDays,
      currentStreak,
    );
    return ((unlockedCount / _achievements.length) * 100).round();
  }
}




