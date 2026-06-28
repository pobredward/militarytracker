import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/config/constants.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'WORKOUT HISTORY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: workoutsAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Color(0xFF00C853),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '운동 기록이 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '운동을 기록해보세요!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(workoutHistoryProvider);
              },
              color: const Color(0xFF00C853),
              backgroundColor: const Color(0xFF1E1E1E),
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  final hasActivity = workout.squatCount > 0 ||
                      workout.lungeCount > 0 ||
                      workout.walkSteps > 0 ||
                      workout.runDistance > 0;

                  return _buildWorkoutCard(context, workout, hasActivity);
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00C853),
            ),
          ),
          error: (error, stack) {
            // 에러 로그 출력
            print('Workout History Error: $error');
            print('Stack trace: $stack');
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCF6679).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFCF6679),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '오류가 발생했습니다',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(workoutHistoryProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, workout, bool hasActivity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActivity ? const Color(0xFF00C853).withOpacity(0.3) : const Color(0xFF2A2A2A),
          width: hasActivity ? 2 : 1,
        ),
        boxShadow: hasActivity
            ? [
                BoxShadow(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF00C853),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                workout.date != null
                    ? DateFormatter.toKoreanDate(workout.date!)
                    : '날짜 없음',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE0E0E0),
                ),
              ),
              const Spacer(),
              if (hasActivity)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 운동 통계
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.accessibility_new_rounded,
                  label: '스쿼트',
                  value: '${workout.squatCount}',
                  unit: '회',
                  progress: workout.squatCount / AppConstants.squatGoal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_run_rounded,
                  label: '런지',
                  value: '${workout.lungeCount}',
                  unit: '회',
                  progress: workout.lungeCount / AppConstants.lungeGoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_walk_rounded,
                  label: '걷기',
                  value: '${workout.walkSteps}',
                  unit: '보',
                  progress: workout.walkSteps / AppConstants.walkGoal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.run_circle_rounded,
                  label: '뛰기',
                  value: workout.runDistance.toStringAsFixed(1),
                  unit: 'km',
                  progress: workout.runDistance / AppConstants.runGoal,
                ),
              ),
            ],
          ),
          
          // 메모가 있는 경우
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workout.notes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required double progress,
  }) {
    final percentage = (progress * 100).clamp(0, 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF00C853),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

