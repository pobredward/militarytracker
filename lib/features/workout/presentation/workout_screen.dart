import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/constants.dart';
import '../../../models/workout_model.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pose_detection_service.dart';
import 'camera_workout_screen.dart';
import 'walking_tracker_screen.dart';
import 'running_tracker_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayWorkout();
    });
  }

  /// 오늘의 운동 데이터 초기 로드
  void _loadTodayWorkout() {
    final todayWorkout = ref.read(todayWorkoutProvider);
    todayWorkout.whenData((workout) {
      if (workout != null && mounted) {
        ref.read(currentWorkoutStateProvider.notifier).state = workout;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkout = ref.watch(currentWorkoutStateProvider);
    final todayWorkoutAsync = ref.watch(todayWorkoutProvider);
    final authState = ref.watch(authStateProvider);

    // 오늘의 운동 데이터가 있으면 로컬 상태에 반영 (실시간 업데이트)
    ref.listen<AsyncValue<WorkoutModel?>>(
      todayWorkoutProvider,
      (previous, next) {
        next.whenData((workout) {
          if (workout != null && mounted) {
            // 현재 상태와 다를 때만 업데이트
            final current = ref.read(currentWorkoutStateProvider);
            if (current.squatCount != workout.squatCount ||
                current.lungeCount != workout.lungeCount ||
                current.walkSteps != workout.walkSteps ||
                current.runDistance != workout.runDistance) {
              ref.read(currentWorkoutStateProvider.notifier).state = workout;
            }
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'WORKOUT',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Color(0xFF00C853),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF9E9E9E)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('운동 기록 화면으로 이동합니다')),
              );
            },
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                '로그인이 필요합니다',
                style: TextStyle(color: Color(0xFF9E9E9E)),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '오늘 ${DateTime.now().month}월 ${DateTime.now().day}일',
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

                  // 스쿼트
                  _buildPremiumWorkoutCard(
                    context,
                    ref,
                    title: 'SQUATS',
                    subtitle: '스쿼트',
                    icon: Icons.accessibility_new_rounded,
                    current: currentWorkout.squatCount,
                    goal: AppConstants.squatGoal,
                    unit: '회',
                    increment: AppConstants.squatIncrement,
                    onUpdate: (value) {
                      ref.read(currentWorkoutStateProvider.notifier).state =
                          currentWorkout.copyWith(squatCount: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 런지
                  _buildPremiumWorkoutCard(
                    context,
                    ref,
                    title: 'LUNGES',
                    subtitle: '런지',
                    icon: Icons.directions_run_rounded,
                    current: currentWorkout.lungeCount,
                    goal: AppConstants.lungeGoal,
                    unit: '회',
                    increment: AppConstants.lungeIncrement,
                    onUpdate: (value) {
                      ref.read(currentWorkoutStateProvider.notifier).state =
                          currentWorkout.copyWith(lungeCount: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 걷기
                  _buildPremiumWorkoutCard(
                    context,
                    ref,
                    title: 'WALKING',
                    subtitle: '걷기',
                    icon: Icons.directions_walk_rounded,
                    current: currentWorkout.walkSteps,
                    goal: AppConstants.walkGoal,
                    unit: '보',
                    increment: AppConstants.walkIncrement,
                    onUpdate: (value) {
                      ref.read(currentWorkoutStateProvider.notifier).state =
                          currentWorkout.copyWith(walkSteps: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 뛰기
                  _buildPremiumRunCard(context, ref, currentWorkout),
                  const SizedBox(height: 32),
                  
                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00C853).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF00C853),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '각 운동의 버튼을 눌러 자동 추적을 시작하세요.\n운동 완료 후 자동으로 기록됩니다.',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00C853))),
        error: (_, __) => const Center(
          child: Text(
            '오류가 발생했습니다',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumWorkoutCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required int current,
    required int goal,
    required String unit,
    required int increment,
    required Function(int) onUpdate,
  }) {
    final progress = current / goal;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00C853),
                  size: 28,
                ),
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
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00C853),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00C853),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$current / $goal $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00E676)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 자동 추적 버튼만 표시 (수동 입력 제거)
          Row(
            children: [
              // 자동 추적 버튼 (스쿼트/런지)
              if (title == 'SQUATS' || title == 'LUNGES')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final exerciseType = title == 'SQUATS'
                          ? ExerciseType.squat
                          : ExerciseType.lunge;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CameraWorkoutScreen(
                            exerciseType: exerciseType,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text(
                      '카메라로 운동하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              // 자동 추적 버튼 (걷기)
              if (title == 'WALKING')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WalkingTrackerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sensors, size: 20),
                    label: const Text(
                      '만보기로 측정하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRunCard(BuildContext context, WidgetRef ref, currentWorkout) {
    final progress = currentWorkout.runDistance / AppConstants.runGoal;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.run_circle_rounded,
                  color: Color(0xFF00C853),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'RUNNING',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00C853),
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '뛰기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00C853),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentWorkout.runDistance.toStringAsFixed(1)} / ${AppConstants.runGoal} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00E676)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),          
          const SizedBox(height: 16),
          
          // GPS 추적 버튼만 표시 (수동 입력 제거)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RunningTrackerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on, size: 20),
                  label: const Text(
                    'GPS로 러닝 추적하기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
