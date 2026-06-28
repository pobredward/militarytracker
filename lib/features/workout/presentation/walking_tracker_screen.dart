import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/tracking_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/config/constants.dart';

/// 걷기 추적 화면 (만보기)
class WalkingTrackerScreen extends ConsumerStatefulWidget {
  const WalkingTrackerScreen({super.key});

  @override
  ConsumerState<WalkingTrackerScreen> createState() => _WalkingTrackerScreenState();
}

class _WalkingTrackerScreenState extends ConsumerState<WalkingTrackerScreen> {
  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    final pedometerService = ref.read(pedometerServiceProvider);
    final permissionStatus = await pedometerService.startTracking();
    
    if (permissionStatus.isGranted) {
      // 추적 시작됨 (resetSteps 제거 - 서비스가 자동으로 처리)
      ref.read(isTrackingPedometerProvider.notifier).state = true;
    } else {
      if (mounted) {
        // 권한이 영구적으로 거부된 경우
        if (permissionStatus.isPermanentlyDenied) {
          _showPermissionDeniedDialog(
            title: '활동 인식 권한 필요',
            message: '걸음 수를 측정하려면 활동 인식 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
          );
        } else {
          // 권한이 거부된 경우
          _showPermissionDeniedDialog(
            title: '활동 인식 권한 필요',
            message: '걸음 수를 측정하려면 활동 인식 권한이 필요합니다.',
          );
        }
      }
    }
  }

  Future<void> _showPermissionDeniedDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '설정으로 이동',
              style: TextStyle(color: Color(0xFF00C853)),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      // 설정 앱 열기
      await openAppSettings();
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _stopAndSave() async {
    final pedometerService = ref.read(pedometerServiceProvider);
    final steps = pedometerService.todaySteps;  // currentSteps → todaySteps
    
    if (steps == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록된 걸음 수가 없습니다')),
        );
      }
      return;
    }

    // 저장
    final workoutActions = ref.read(workoutActionProvider);
    final success = await workoutActions.saveOrUpdateTodayWorkout(
      walkSteps: steps,
    );

    // 추적 중지
    await pedometerService.stopTracking();
    ref.read(isTrackingPedometerProvider.notifier).state = false;

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$steps걸음 저장되었습니다!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 실패')),
        );
      }
    }
  }

  @override
  void dispose() {
    final pedometerService = ref.read(pedometerServiceProvider);
    pedometerService.stopTracking();
    ref.read(isTrackingPedometerProvider.notifier).state = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepCountAsync = ref.watch(stepCountStreamProvider);
    final isTracking = ref.watch(isTrackingPedometerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '걷기 추적',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 걸음 수 표시
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    stepCountAsync.when(
                      data: (steps) => Text(
                        '$steps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      '걸음',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 목표 대비 진행률
              stepCountAsync.when(
                data: (steps) {
                  final progress = (steps / AppConstants.walkGoal).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade400,
                        ),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '목표: ${AppConstants.walkGoal}걸음 (${(progress * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              const Spacer(),
              
              // 안내 텍스트
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '걸음 수가 자동으로 측정됩니다.\n완료 후 저장 버튼을 눌러주세요.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isTracking ? _stopAndSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




