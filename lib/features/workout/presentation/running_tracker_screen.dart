import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../../providers/tracking_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/config/constants.dart';

/// 러닝 추적 화면 (GPS 기반)
class RunningTrackerScreen extends ConsumerStatefulWidget {
  const RunningTrackerScreen({super.key});

  @override
  ConsumerState<RunningTrackerScreen> createState() => _RunningTrackerScreenState();
}

class _RunningTrackerScreenState extends ConsumerState<RunningTrackerScreen> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    final runningService = ref.read(runningTrackerServiceProvider);
    final permissionStatus = await runningService.startTracking();
    
    if (permissionStatus.isGranted) {
      ref.read(isTrackingRunningProvider.notifier).state = true;
      _startTimer();
    } else {
      if (mounted) {
        // 권한이 영구적으로 거부된 경우
        if (permissionStatus.isPermanentlyDenied) {
          _showPermissionDeniedDialog(
            title: '위치 권한 필요',
            message: 'GPS로 러닝 거리를 측정하려면 위치 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
          );
        } else {
          // 권한이 거부된 경우
          _showPermissionDeniedDialog(
            title: '위치 권한 필요',
            message: 'GPS로 러닝 거리를 측정하려면 위치 권한이 필요합니다.',
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
              style: TextStyle(color: Color(0xFFFF9800)),
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _togglePause() async {
    final runningService = ref.read(runningTrackerServiceProvider);
    
    if (_isPaused) {
      // 재개
      await runningService.resumeTracking();
      setState(() {
        _isPaused = false;
      });
    } else {
      // 일시정지
      await runningService.pauseTracking();
      setState(() {
        _isPaused = true;
      });
    }
  }

  Future<void> _stopAndSave() async {
    final runningService = ref.read(runningTrackerServiceProvider);
    final distance = runningService.sessionDistance;  // totalDistance → sessionDistance
    
    if (distance == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록된 거리가 없습니다')),
        );
      }
      return;
    }

    // 저장 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '운동 저장',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '${distance.toStringAsFixed(2)}km를 저장하시겠습니까?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 저장
    final workoutActions = ref.read(workoutActionProvider);
    final success = await workoutActions.saveOrUpdateTodayWorkout(
      runDistance: distance,
      duration: _elapsedTime.inSeconds,
    );

    // 추적 중지
    _timer?.cancel();
    await runningService.stopTracking();
    ref.read(isTrackingRunningProvider.notifier).state = false;

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${distance.toStringAsFixed(2)}km 저장되었습니다!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 실패')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    final runningService = ref.read(runningTrackerServiceProvider);
    runningService.stopTracking();
    ref.read(isTrackingRunningProvider.notifier).state = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distanceAsync = ref.watch(runningDistanceStreamProvider);
    final speedAsync = ref.watch(runningSpeedStreamProvider);
    final isTracking = ref.watch(isTrackingRunningProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '러닝 추적',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  '추적 중단',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  '추적을 중단하고 나가시겠습니까?\n저장되지 않은 데이터는 사라집니다.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('나가기'),
                  ),
                ],
              ),
            );
            
            if (confirm == true && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // 거리 표시
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_run,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    distanceAsync.when(
                      data: (distance) => Text(
                        distance.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text(
                        '0.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => const Text(
                        '0.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      'km',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 통계 카드
              Row(
                children: [
                  // 시간
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer,
                      label: '시간',
                      value: _formatDuration(_elapsedTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 속도
                  Expanded(
                    child: speedAsync.when(
                      data: (speed) => _buildStatCard(
                        icon: Icons.speed,
                        label: '속도',
                        value: '${speed.toStringAsFixed(1)} km/h',
                      ),
                      loading: () => _buildStatCard(
                        icon: Icons.speed,
                        label: '속도',
                        value: '0.0 km/h',
                      ),
                      error: (_, __) => _buildStatCard(
                        icon: Icons.speed,
                        label: '속도',
                        value: '0.0 km/h',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 목표 대비 진행률
              distanceAsync.when(
                data: (distance) {
                  final progress = (distance / AppConstants.runGoal).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange.shade400,
                        ),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '목표: ${AppConstants.runGoal}km (${(progress * 100).toStringAsFixed(0)}%)',
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
              
              // 컨트롤 버튼
              Row(
                children: [
                  // 일시정지/재개 버튼
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isTracking ? _togglePause : null,
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isPaused ? '재개' : '일시정지',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          disabledBackgroundColor: Colors.grey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 저장 버튼
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isTracking ? _stopAndSave : null,
                        icon: const Icon(
                          Icons.save,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          disabledBackgroundColor: Colors.grey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
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
                        'GPS로 이동 거리를 측정합니다.\n백그라운드에서도 추적이 계속됩니다.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.orange.shade400,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}




