import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/workout_repository.dart';
import 'auth_provider.dart';

// 실시간 운동 통계 Provider (workouts 데이터에서 계산)
final realTimeStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.read(workoutRepositoryProvider);

  return await authState.when(
    data: (user) async {
      if (user == null) {
        return {
          'totalSquats': 0,
          'totalLunges': 0,
          'totalWalkSteps': 0,
          'totalRunDistance': 0.0,
          'workoutDays': 0,
        };
      }
      
      return await workoutRepository.getTotalStats(user.uid);
    },
    loading: () async => {
      'totalSquats': 0,
      'totalLunges': 0,
      'totalWalkSteps': 0,
      'totalRunDistance': 0.0,
      'workoutDays': 0,
    },
    error: (_, __) async => {
      'totalSquats': 0,
      'totalLunges': 0,
      'totalWalkSteps': 0,
      'totalRunDistance': 0.0,
      'workoutDays': 0,
    },
  );
});

// Streak (연속 운동일) 계산 Provider
final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final workoutRepository = ref.read(workoutRepositoryProvider);

  return await authState.when(
    data: (user) async {
      if (user == null) return 0;
      
      try {
        // 최근 60일의 운동 기록 조회
        final workouts = await workoutRepository.getWorkoutHistory(user.uid, limit: 60);
        
        if (workouts.isEmpty) return 0;
        
        // 날짜별로 정렬 (최신순)
        workouts.sort((a, b) {
          if (a.date == null || b.date == null) return 0;
          return b.date!.compareTo(a.date!);
        });
        
        int streak = 0;
        DateTime? previousDate;
        final today = DateTime.now();
        
        for (var workout in workouts) {
          if (workout.date == null) continue;
          
          final workoutDate = DateTime(
            workout.date!.year,
            workout.date!.month,
            workout.date!.day,
          );
          
          if (previousDate == null) {
            // 첫 번째 운동
            // 오늘이거나 어제여야 streak 시작
            final todayDate = DateTime(today.year, today.month, today.day);
            final yesterdayDate = todayDate.subtract(const Duration(days: 1));
            
            if (workoutDate.isAtSameMomentAs(todayDate) || 
                workoutDate.isAtSameMomentAs(yesterdayDate)) {
              streak = 1;
              previousDate = workoutDate;
            } else {
              // 연속이 끊김
              break;
            }
          } else {
            // 이전 날짜의 하루 전이어야 함
            final expectedDate = previousDate.subtract(const Duration(days: 1));
            
            if (workoutDate.isAtSameMomentAs(expectedDate)) {
              streak++;
              previousDate = workoutDate;
            } else if (workoutDate.isBefore(expectedDate)) {
              // 연속이 끊김
              break;
            }
            // 같은 날짜는 무시 (이미 카운트됨)
          }
        }
        
        return streak;
      } catch (e) {
        return 0;
      }
    },
    loading: () async => 0,
    error: (_, __) async => 0,
  );
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});
