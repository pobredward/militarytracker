import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/workout_repository.dart';
import '../repositories/auth_repository.dart';
import '../models/workout_model.dart';
import '../core/config/logger.dart';
import 'auth_provider.dart';

// WorkoutRepository Provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// 오늘의 운동 Provider (Stream) - 개선된 날짜 비교
final todayWorkoutProvider = StreamProvider.autoDispose<WorkoutModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      
      // 오늘 날짜로 필터링된 운동 기록 스트림
      return workoutRepository.workoutHistoryStream(user.uid, limit: 1).map(
        (workouts) {
          if (workouts.isEmpty) return null;
          final workout = workouts.first;
          
          // 날짜 비교 (로컬 타임존 기준)
          final today = DateTime.now();
          final workoutDate = workout.date;
          
          // 날짜만 비교 (시간 제거)
          final isSameDay = workoutDate.year == today.year &&
              workoutDate.month == today.month &&
              workoutDate.day == today.day;
              
          return isSameDay ? workout : null;
        },
      );
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// 운동 기록 히스토리 Provider (Stream)
final workoutHistoryProvider = StreamProvider.autoDispose<List<WorkoutModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        logger.d('WorkoutHistory: User is null');
        return Stream.value([]);
      }
      logger.d('WorkoutHistory: Fetching for user ${user.uid}');
      return workoutRepository.workoutHistoryStream(user.uid, limit: 30).handleError((error) {
        AppLogger.e('WorkoutHistory Stream Error', error);
      });
    },
    loading: () {
      logger.d('WorkoutHistory: Auth loading');
      return Stream.value([]);
    },
    error: (error, stack) {
      AppLogger.e('WorkoutHistory: Auth error', error, stack);
      return Stream.value([]);
    },
  );
});

// 이번 주 운동 데이터 Provider (월요일부터 오늘까지)
final weeklyWorkoutProvider = FutureProvider.autoDispose<List<WorkoutModel?>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  
  // ✅ todayWorkoutProvider를 watch하여 오늘 데이터 변경 시 자동 갱신
  ref.watch(todayWorkoutProvider);

  return await authState.when(
    data: (user) async {
      if (user == null) return List.filled(7, null);
      
      final now = DateTime.now();
      final weekday = now.weekday; // 1 = 월요일, 7 = 일요일
      
      // 이번 주 월요일 계산
      final monday = now.subtract(Duration(days: weekday - 1));
      
      // 7일간의 운동 데이터 조회
      final List<WorkoutModel?> weeklyData = [];
      
      for (int i = 0; i < 7; i++) {
        final targetDate = DateTime(
          monday.year,
          monday.month,
          monday.day + i,
        );
        
        // 미래 날짜는 null
        if (targetDate.isAfter(now)) {
          weeklyData.add(null);
        } else {
          try {
            final workout = await workoutRepository.getWorkoutByDate(user.uid, targetDate);
            weeklyData.add(workout);
          } catch (e) {
            logger.e('Error fetching workout for $targetDate: $e');
            weeklyData.add(null);
          }
        }
      }
      
      return weeklyData;
    },
    loading: () async => List.filled(7, null),
    error: (_, __) async => List.filled(7, null),
  );
});

// 현재 운동 상태 StateProvider (로컬 상태 - UI에서 사용)
final currentWorkoutStateProvider = StateProvider<WorkoutModel>((ref) {
  return WorkoutModel(
    date: DateTime.now(),
    userId: '',
  );
});

// Workout Actions Provider
final workoutActionProvider = Provider<WorkoutActions>((ref) {
  return WorkoutActions(ref);
});

class WorkoutActions {
  final Ref ref;
  
  WorkoutActions(this.ref);
  
  WorkoutRepository get _workoutRepository => ref.read(workoutRepositoryProvider);
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  
  // 현재 사용자 ID 가져오기
  String? get _currentUserId => _authRepository.currentUser?.uid;
  
  // 오늘의 운동 기록 생성 또는 업데이트
  Future<bool> saveOrUpdateTodayWorkout({
    int? squatCount,
    int? lungeCount,
    int? walkSteps,
    double? runDistance,
    int? duration,
    String? notes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    
    try {
      // 오늘의 기록이 있는지 확인
      final existingWorkout = await _workoutRepository.getTodayWorkout(userId);
      
      if (existingWorkout != null) {
        // 기존 기록 업데이트
        final updatedWorkout = existingWorkout.copyWith(
          squatCount: squatCount ?? existingWorkout.squatCount,
          lungeCount: lungeCount ?? existingWorkout.lungeCount,
          walkSteps: walkSteps ?? existingWorkout.walkSteps,
          runDistance: runDistance ?? existingWorkout.runDistance,
          duration: duration ?? existingWorkout.duration,
          notes: notes ?? existingWorkout.notes,
        );
        
        return await _workoutRepository.updateWorkout(updatedWorkout);
      } else {
        // 새 기록 생성
        final newWorkout = WorkoutModel(
          userId: userId,
          squatCount: squatCount ?? 0,
          lungeCount: lungeCount ?? 0,
          walkSteps: walkSteps ?? 0,
          runDistance: runDistance ?? 0.0,
          duration: duration ?? 0,
          notes: notes,
          date: DateTime.now(),
        );
        
        final workoutId = await _workoutRepository.createWorkout(newWorkout);
        return workoutId != null;
      }
    } catch (e) {
      return false;
    }
  }
  
  // 스쿼트 카운트 추가 (누적) - 에러 처리 개선
  Future<bool> addSquatCount(int count) async {
    final userId = _currentUserId;
    if (userId == null) {
      logger.e('Cannot add squat count: user not logged in');
      return false;
    }
    
    if (count <= 0) return true; // 0이하면 저장하지 않음
    
    try {
      logger.i('Adding squat count: $count for user: $userId');
      final existingWorkout = await _workoutRepository.getTodayWorkout(userId);
      
      if (existingWorkout != null) {
        logger.i('Existing workout found, updating from ${existingWorkout.squatCount} to ${existingWorkout.squatCount + count}');
        final updated = existingWorkout.copyWith(
          squatCount: existingWorkout.squatCount + count,
        );
        final result = await _workoutRepository.updateWorkout(updated);
        logger.i('Squat count update result: $result');
        return result;
      } else {
        logger.i('No existing workout, creating new workout with $count squats');
        final newWorkout = WorkoutModel(
          userId: userId,
          squatCount: count,
          date: DateTime.now(),
        );
        final workoutId = await _workoutRepository.createWorkout(newWorkout);
        logger.i('New workout created with id: $workoutId');
        return workoutId != null;
      }
    } catch (e, stackTrace) {
      logger.e('Error adding squat count: $e');
      logger.e('Stack trace: $stackTrace');
      return false;
    }
  }
  
  // 런지 카운트 추가 (누적) - 에러 처리 개선
  Future<bool> addLungeCount(int count) async {
    final userId = _currentUserId;
    if (userId == null) {
      logger.e('Cannot add lunge count: user not logged in');
      return false;
    }
    
    if (count <= 0) return true; // 0이하면 저장하지 않음
    
    try {
      logger.i('Adding lunge count: $count for user: $userId');
      final existingWorkout = await _workoutRepository.getTodayWorkout(userId);
      
      if (existingWorkout != null) {
        logger.i('Existing workout found, updating from ${existingWorkout.lungeCount} to ${existingWorkout.lungeCount + count}');
        final updated = existingWorkout.copyWith(
          lungeCount: existingWorkout.lungeCount + count,
        );
        final result = await _workoutRepository.updateWorkout(updated);
        logger.i('Lunge count update result: $result');
        return result;
      } else {
        logger.i('No existing workout, creating new workout with $count lunges');
        final newWorkout = WorkoutModel(
          userId: userId,
          lungeCount: count,
          date: DateTime.now(),
        );
        final workoutId = await _workoutRepository.createWorkout(newWorkout);
        logger.i('New workout created with id: $workoutId');
        return workoutId != null;
      }
    } catch (e, stackTrace) {
      logger.e('Error adding lunge count: $e');
      logger.e('Stack trace: $stackTrace');
      return false;
    }
  }
  
  // 스쿼트 카운트 증가 (레거시 호환성)
  @Deprecated('Use addSquatCount instead')
  Future<bool> incrementSquat(int count) => addSquatCount(count);
  
  // 런지 카운트 증가 (레거시 호환성)
  @Deprecated('Use addLungeCount instead')
  Future<bool> incrementLunge(int count) => addLungeCount(count);
  
  // 걷기 걸음수 추가
  Future<bool> addWalkSteps(int steps) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    
    try {
      final existingWorkout = await _workoutRepository.getTodayWorkout(userId);
      
      if (existingWorkout != null) {
        final updated = existingWorkout.copyWith(
          walkSteps: existingWorkout.walkSteps + steps,
        );
        return await _workoutRepository.updateWorkout(updated);
      } else {
        final newWorkout = WorkoutModel(
          userId: userId,
          walkSteps: steps,
          date: DateTime.now(),
        );
        final workoutId = await _workoutRepository.createWorkout(newWorkout);
        return workoutId != null;
      }
    } catch (e) {
      return false;
    }
  }
  
  // 달리기 거리 추가
  Future<bool> addRunDistance(double distance) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    
    try {
      final existingWorkout = await _workoutRepository.getTodayWorkout(userId);
      
      if (existingWorkout != null) {
        final updated = existingWorkout.copyWith(
          runDistance: existingWorkout.runDistance + distance,
        );
        return await _workoutRepository.updateWorkout(updated);
      } else {
        final newWorkout = WorkoutModel(
          userId: userId,
          runDistance: distance,
          date: DateTime.now(),
        );
        final workoutId = await _workoutRepository.createWorkout(newWorkout);
        return workoutId != null;
      }
    } catch (e) {
      return false;
    }
  }
  
  // 특정 날짜의 운동 기록 가져오기
  Future<WorkoutModel?> getWorkoutByDate(DateTime date) async {
    final userId = _currentUserId;
    if (userId == null) return null;
    
    return await _workoutRepository.getWorkoutByDate(userId, date);
  }
  
  // 운동 기록 삭제
  Future<bool> deleteWorkout(String workoutId) async {
    return await _workoutRepository.deleteWorkout(workoutId);
  }
  
  // 총 운동 통계 가져오기
  Future<Map<String, dynamic>> getTotalStats() async {
    final userId = _currentUserId;
    if (userId == null) {
      return {
        'totalSquats': 0,
        'totalLunges': 0,
        'totalWalkSteps': 0,
        'totalRunDistance': 0.0,
        'workoutDays': 0,
      };
    }
    
    return await _workoutRepository.getTotalStats(userId);
  }
}
