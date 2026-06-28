import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../../services/pose_detection_service.dart';
import '../../../providers/tracking_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/config/logger.dart';

/// 카메라 기반 운동 추적 화면 (스쿼트/런지)
class CameraWorkoutScreen extends ConsumerStatefulWidget {
  final ExerciseType exerciseType;

  const CameraWorkoutScreen({
    super.key,
    required this.exerciseType,
  });

  @override
  ConsumerState<CameraWorkoutScreen> createState() => _CameraWorkoutScreenState();
}

class _CameraWorkoutScreenState extends ConsumerState<CameraWorkoutScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _previousCount = 0;  // 기존 카운트 (누적용)

  @override
  void initState() {
    super.initState();
    _loadPreviousCount();
    _initializeCamera();
  }

  /// 기존 카운트 불러오기
  Future<void> _loadPreviousCount() async {
    try {
      final workoutActions = ref.read(workoutActionProvider);
      final existingWorkout = await workoutActions.getWorkoutByDate(DateTime.now());
      
      if (existingWorkout != null) {
        if (widget.exerciseType == ExerciseType.squat) {
          _previousCount = existingWorkout.squatCount;
        } else {
          _previousCount = existingWorkout.lungeCount;
        }
        
        logger.i('Loaded previous count: $_previousCount');
      }
    } catch (e) {
      logger.e('Error loading previous count: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      logger.i('🎥 Initializing camera for ${widget.exerciseType}...');
      
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        logger.e('❌ No cameras available');
        return;
      }

      logger.i('📷 Found ${_cameras!.length} cameras');

      // 전면 카메라 선택
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      logger.i('🎯 Using camera: ${frontCamera.name} (${frontCamera.lensDirection})');

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      logger.i('✅ Camera initialized successfully');

      // 운동 타입 설정
      final poseService = ref.read(poseDetectionServiceProvider);
      poseService.setExerciseType(widget.exerciseType);
      
      logger.i('🏋️ Exercise type set to: ${widget.exerciseType}');

      // 이미지 스트림 시작
      _cameraController!.startImageStream(_processImage);
      
      logger.i('▶️  Image stream started');
    } catch (e) {
      logger.e('❌ Error initializing camera: $e');
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final poseService = ref.read(poseDetectionServiceProvider);
      await poseService.processImage(image, _cameraController!.description);
    } catch (e) {
      logger.e('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _saveWorkout() async {
    final poseService = ref.read(poseDetectionServiceProvider);
    final sessionCount = poseService.currentCount;  // 현재 세션 카운트
    
    if (sessionCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이번 세션에서 운동 기록이 없습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 총 카운트 = 기존 + 이번 세션
    final totalCount = _previousCount + sessionCount;

    final workoutActions = ref.read(workoutActionProvider);
    
    bool success = false;
    if (widget.exerciseType == ExerciseType.squat) {
      // addSquatCount 사용 (누적)
      success = await workoutActions.addSquatCount(sessionCount);
    } else {
      // addLungeCount 사용 (누적)
      success = await workoutActions.addLungeCount(sessionCount);
    }

    if (mounted) {
      if (success) {
        final exerciseName = widget.exerciseType == ExerciseType.squat ? '스쿼트' : '런지';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$exerciseName +$sessionCount개 저장!\n오늘 총 $totalCount개',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final exerciseName = widget.exerciseType == ExerciseType.squat ? '스쿼트' : '런지';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$exerciseName 저장 실패. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 뒤로가기 시 자동 저장 (조용하게)
  Future<void> _saveWorkoutSilently() async {
    final poseService = ref.read(poseDetectionServiceProvider);
    final sessionCount = poseService.currentCount;
    
    if (sessionCount == 0) return;  // 기록이 없으면 저장하지 않음
    
    final workoutActions = ref.read(workoutActionProvider);
    
    if (widget.exerciseType == ExerciseType.squat) {
      await workoutActions.addSquatCount(sessionCount);
    } else {
      await workoutActions.addLungeCount(sessionCount);
    }
  }

  /// 화면 나가기 처리
  Future<void> _handleExit() async {
    await _saveWorkoutSilently();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poseCount = ref.watch(poseCountStreamProvider);
    final exerciseName = widget.exerciseType == ExerciseType.squat
        ? '스쿼트'
        : '런지';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '$exerciseName 카운팅',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleExit,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveWorkout,
              tooltip: '저장',
            ),
          ],
        ),
        body: _isInitialized && _cameraController != null
            ? Stack(
                children: [
                  // 카메라 프리뷰
                  Center(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                  
                  // 카운트 오버레이 (개선된 UI)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          // 이번 세션 카운트
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00C853).withOpacity(0.9),
                                  const Color(0xFF00E676).withOpacity(0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C853).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: poseCount.when(
                              data: (count) => Column(
                                children: [
                                  const Text(
                                    '이번 세션',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
                          ),
                          
                          // 오늘 총 카운트 (기존 + 현재)
                          if (_previousCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00C853).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: poseCount.when(
                                data: (count) => Text(
                                  '오늘 총: ${_previousCount + count}개',
                                  style: const TextStyle(
                                    color: Color(0xFF00C853),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                loading: () => Text(
                                  '오늘 총: $_previousCount개',
                                  style: const TextStyle(
                                    color: Color(0xFF00C853),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                error: (_, __) => Text(
                                  '오늘 총: $_previousCount개',
                                  style: const TextStyle(
                                    color: Color(0xFF00C853),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 가이드 텍스트
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.exerciseType == ExerciseType.squat
                              ? '카메라에 전신이 보이도록 하고\n스쿼트를 시작하세요'
                              : '카메라에 전신이 보이도록 하고\n런지를 시작하세요',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

