import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pose_detection_service.dart';
import '../services/pedometer_service.dart';
import '../services/running_tracker_service.dart';

// Pose Detection Service Provider
final poseDetectionServiceProvider = Provider<PoseDetectionService>((ref) {
  final service = PoseDetectionService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Pedometer Service Provider (백그라운드 지원 - autoDispose 제거)
final pedometerServiceProvider = Provider<PedometerService>((ref) {
  final service = PedometerService();
  
  // Ref 설정 (Firebase 저장용)
  service.setRef(ref);
  
  // 앱 시작 시 저장된 추적 상태 복원
  service.restoreTrackingState();
  
  // 앱이 완전히 종료될 때만 dispose
  ref.onDispose(() => service.dispose());
  return service;
});

// Running Tracker Service Provider
final runningTrackerServiceProvider = Provider<RunningTrackerService>((ref) {
  final service = RunningTrackerService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Pose Detection Count Stream Provider
final poseCountStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final service = ref.watch(poseDetectionServiceProvider);
  return service.countStream;
});

// Pedometer Step Count Stream Provider (백그라운드 지원 - autoDispose 제거)
final stepCountStreamProvider = StreamProvider<int>((ref) {
  final service = ref.watch(pedometerServiceProvider);
  return service.stepCountStream;
});

// Running Distance Stream Provider
final runningDistanceStreamProvider = StreamProvider.autoDispose<double>((ref) {
  final service = ref.watch(runningTrackerServiceProvider);
  return service.distanceStream;
});

// Running Speed Stream Provider
final runningSpeedStreamProvider = StreamProvider.autoDispose<double>((ref) {
  final service = ref.watch(runningTrackerServiceProvider);
  return service.speedStream;
});

// Tracking State Providers
final isTrackingPedometerProvider = StateProvider<bool>((ref) => false);
final isTrackingRunningProvider = StateProvider<bool>((ref) => false);
final isPoseDetectionActiveProvider = StateProvider<bool>((ref) => false);

// Exercise Type Provider (for pose detection)
final currentExerciseTypeProvider = StateProvider<ExerciseType>(
  (ref) => ExerciseType.squat,
);

