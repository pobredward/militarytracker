import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/statistics_provider.dart';
import '../../../core/config/constants.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realTimeStats = ref.watch(realTimeStatsProvider);
    final workoutHistory = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'STATISTICS',
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
            Tab(text: '주간'),
            Tab(text: '월간'),
          ],
        ),
      ),
      body: SafeArea(
        child: realTimeStats.when(
          data: (stats) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverallStats(stats),
                _buildWeeklyStats(workoutHistory),
                _buildMonthlyStats(workoutHistory),
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
        ),
      ),
    );
  }

  Widget _buildOverallStats(Map<String, dynamic> stats) {
    final totalSquats = stats['totalSquats'] as int;
    final totalLunges = stats['totalLunges'] as int;
    final totalWalkSteps = stats['totalWalkSteps'] as int;
    final totalRunDistance = stats['totalRunDistance'] as double;
    final workoutDays = stats['workoutDays'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 요약 카드
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C853).withOpacity(0.2),
                  const Color(0xFF00C853).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00C853).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF00C853),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  '총 운동일',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$workoutDays일',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00C853),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '계속 달려나가세요! 💪',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 운동별 통계
          _buildSectionHeader('운동별 총계', Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          _buildStatCard(
            title: '스쿼트',
            icon: Icons.accessibility_new_rounded,
            value: totalSquats.toString(),
            unit: '회',
            color: const Color(0xFF00C853),
            progress: (totalSquats / (AppConstants.squatGoal * 100)).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: '런지',
            icon: Icons.directions_run_rounded,
            value: totalLunges.toString(),
            unit: '회',
            color: const Color(0xFF2196F3),
            progress: (totalLunges / (AppConstants.lungeGoal * 100)).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: '걷기',
            icon: Icons.directions_walk_rounded,
            value: NumberFormat('#,###').format(totalWalkSteps),
            unit: '보',
            color: const Color(0xFF9C27B0),
            progress: (totalWalkSteps / (AppConstants.walkGoal * 30)).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: '달리기',
            icon: Icons.run_circle_rounded,
            value: totalRunDistance.toStringAsFixed(1),
            unit: 'km',
            color: const Color(0xFFFF5722),
            progress: (totalRunDistance / (AppConstants.runGoal * 50)).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 24),

          // 평균 통계
          _buildSectionHeader('일일 평균', Icons.insights_rounded),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                _buildAverageItem(
                  icon: Icons.accessibility_new_rounded,
                  label: '스쿼트',
                  value: workoutDays > 0 ? (totalSquats / workoutDays).toStringAsFixed(1) : '0',
                  color: const Color(0xFF00C853),
                ),
                const Divider(height: 24, color: Color(0xFF2A2A2A)),
                _buildAverageItem(
                  icon: Icons.directions_run_rounded,
                  label: '런지',
                  value: workoutDays > 0 ? (totalLunges / workoutDays).toStringAsFixed(1) : '0',
                  color: const Color(0xFF2196F3),
                ),
                const Divider(height: 24, color: Color(0xFF2A2A2A)),
                _buildAverageItem(
                  icon: Icons.directions_walk_rounded,
                  label: '걷기',
                  value: workoutDays > 0 ? (totalWalkSteps / workoutDays).toStringAsFixed(0) : '0',
                  color: const Color(0xFF9C27B0),
                ),
                const Divider(height: 24, color: Color(0xFF2A2A2A)),
                _buildAverageItem(
                  icon: Icons.run_circle_rounded,
                  label: '달리기',
                  value: workoutDays > 0 ? (totalRunDistance / workoutDays).toStringAsFixed(2) : '0',
                  color: const Color(0xFFFF5722),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(AsyncValue workoutHistory) {
    return workoutHistory.when(
      data: (workouts) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        
        final weekWorkouts = workouts.where((w) {
          if (w.date == null) return false;
          final date = w.date!;
          return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                 date.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();

        int weekSquats = 0;
        int weekLunges = 0;
        int weekWalkSteps = 0;
        double weekRunDistance = 0.0;
        
        for (var w in weekWorkouts) {
          weekSquats = (weekSquats + w.squatCount).toInt();
          weekLunges = (weekLunges + w.lungeCount).toInt();
          weekWalkSteps = (weekWalkSteps + w.walkSteps).toInt();
          weekRunDistance += w.runDistance;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기간 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.15),
                      const Color(0xFF2196F3).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                    const SizedBox(width: 12),
                    Text(
                      '${DateFormat('M/d').format(weekStart)} - ${DateFormat('M/d').format(weekEnd)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 이번 주 통계
              _buildSectionHeader('이번 주 기록', Icons.trending_up_rounded),
              const SizedBox(height: 16),
              _buildStatCard(
                title: '스쿼트',
                icon: Icons.accessibility_new_rounded,
                value: weekSquats.toString(),
                unit: '회',
                color: const Color(0xFF00C853),
                subtitle: '목표: ${AppConstants.squatGoal * 7}회',
                progress: (weekSquats / (AppConstants.squatGoal * 7)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: '런지',
                icon: Icons.directions_run_rounded,
                value: weekLunges.toString(),
                unit: '회',
                color: const Color(0xFF2196F3),
                subtitle: '목표: ${AppConstants.lungeGoal * 7}회',
                progress: (weekLunges / (AppConstants.lungeGoal * 7)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: '걷기',
                icon: Icons.directions_walk_rounded,
                value: NumberFormat('#,###').format(weekWalkSteps),
                unit: '보',
                color: const Color(0xFF9C27B0),
                subtitle: '목표: ${NumberFormat('#,###').format(AppConstants.walkGoal * 7)}보',
                progress: (weekWalkSteps / (AppConstants.walkGoal * 7)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: '달리기',
                icon: Icons.run_circle_rounded,
                value: weekRunDistance.toStringAsFixed(1),
                unit: 'km',
                color: const Color(0xFFFF5722),
                subtitle: '목표: ${AppConstants.runGoal * 7}km',
                progress: (weekRunDistance / (AppConstants.runGoal * 7)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 24),

              // 운동일 현황
              _buildSectionHeader('운동일 현황', Icons.check_circle_rounded),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final day = weekStart.add(Duration(days: index));
                    final hasWorkout = weekWorkouts.any((w) {
                      if (w.date == null) return false;
                      return w.date!.year == day.year &&
                             w.date!.month == day.month &&
                             w.date!.day == day.day;
                    });
                    
                    return Column(
                      children: [
                        Text(
                          ['월', '화', '수', '목', '금', '토', '일'][index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasWorkout 
                                ? const Color(0xFF00C853)
                                : const Color(0xFF616161),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hasWorkout 
                                ? const Color(0xFF00C853)
                                : const Color(0xFF2A2A2A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasWorkout 
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 18,
                            color: hasWorkout 
                                ? Colors.black
                                : const Color(0xFF616161),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
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
    );
  }

  Widget _buildMonthlyStats(AsyncValue workoutHistory) {
    return workoutHistory.when(
      data: (workouts) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        
        final monthWorkouts = workouts.where((w) {
          if (w.date == null) return false;
          final date = w.date!;
          return date.year == now.year && date.month == now.month;
        }).toList();

        int monthSquats = 0;
        int monthLunges = 0;
        int monthWalkSteps = 0;
        double monthRunDistance = 0.0;
        
        for (var w in monthWorkouts) {
          monthSquats = (monthSquats + w.squatCount).toInt();
          monthLunges = (monthLunges + w.lungeCount).toInt();
          monthWalkSteps = (monthWalkSteps + w.walkSteps).toInt();
          monthRunDistance += w.runDistance;
        }

        final daysInMonth = monthEnd.day;
        final workoutDays = monthWorkouts.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기간 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9C27B0).withOpacity(0.15),
                      const Color(0xFF9C27B0).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF9C27B0)),
                    const SizedBox(width: 12),
                    Text(
                      '${now.year}년 ${now.month}월',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$workoutDays / $daysInMonth일',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 이번 달 통계
              _buildSectionHeader('이번 달 기록', Icons.bar_chart_rounded),
              const SizedBox(height: 16),
              _buildStatCard(
                title: '스쿼트',
                icon: Icons.accessibility_new_rounded,
                value: monthSquats.toString(),
                unit: '회',
                color: const Color(0xFF00C853),
                subtitle: '목표: ${AppConstants.squatGoal * daysInMonth}회',
                progress: (monthSquats / (AppConstants.squatGoal * daysInMonth)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: '런지',
                icon: Icons.directions_run_rounded,
                value: monthLunges.toString(),
                unit: '회',
                color: const Color(0xFF2196F3),
                subtitle: '목표: ${AppConstants.lungeGoal * daysInMonth}회',
                progress: (monthLunges / (AppConstants.lungeGoal * daysInMonth)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: '걷기',
                icon: Icons.directions_walk_rounded,
                value: NumberFormat('#,###').format(monthWalkSteps),
                unit: '보',
                color: const Color(0xFF9C27B0),
                subtitle: '목표: ${NumberFormat('#,###').format(AppConstants.walkGoal * daysInMonth)}보',
                progress: (monthWalkSteps / (AppConstants.walkGoal * daysInMonth)).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: '달리기',
                icon: Icons.run_circle_rounded,
                value: monthRunDistance.toStringAsFixed(1),
                unit: 'km',
                color: const Color(0xFFFF5722),
                subtitle: '목표: ${AppConstants.runGoal * daysInMonth}km',
                progress: (monthRunDistance / (AppConstants.runGoal * daysInMonth)).clamp(0.0, 1.0),
              ),
            ],
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00C853), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE0E0E0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
    String? subtitle,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          TextSpan(
                            text: ' $unit',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

