import 'package:flutter_test/flutter_test.dart';
import 'package:militarytracker/repositories/workout_repository.dart';
import 'package:militarytracker/models/workout_model.dart';
import 'package:militarytracker/core/config/scoring_config.dart';

/// WorkoutRepository 통합 테스트
/// 
/// 실제 Firestore 대신 Mock을 사용하여 테스트합니다.
/// 
/// 참고: 실제 Firestore 테스트는 integration_test에서 수행합니다.
void main() {
  group('WorkoutRepository Unit Tests', () {
    test('WorkoutRepositoryException has correct error types', () {
      final exception = WorkoutRepositoryException(
        type: WorkoutRepositoryError.networkError,
        message: 'Network error occurred',
      );

      expect(exception.type, equals(WorkoutRepositoryError.networkError));
      expect(exception.message, equals('Network error occurred'));
    });

    test('WorkoutRepositoryException toString includes type and message', () {
      final exception = WorkoutRepositoryException(
        type: WorkoutRepositoryError.invalidData,
        message: 'Invalid data',
      );

      expect(
        exception.toString(),
        contains('invalidData'),
      );
      expect(
        exception.toString(),
        contains('Invalid data'),
      );
    });

    test('WorkoutModel can be created with required fields', () {
      final workout = WorkoutModel(
        userId: 'test-user',
        date: DateTime(2026, 3, 23),
      );

      expect(workout.userId, equals('test-user'));
      expect(workout.squatCount, equals(0));
      expect(workout.lungeCount, equals(0));
      expect(workout.walkSteps, equals(0));
      expect(workout.runDistance, equals(0.0));
    });

    test('WorkoutModel copyWith works correctly', () {
      final workout = WorkoutModel(
        userId: 'test-user',
        squatCount: 50,
        date: DateTime(2026, 3, 23),
      );

      final updated = workout.copyWith(squatCount: 100);

      expect(updated.squatCount, equals(100));
      expect(updated.userId, equals('test-user'));
    });
  });

  group('Scoring Integration Tests', () {
    test('Score calculation matches expected values', () {
      final workout = WorkoutModel(
        userId: 'test-user',
        squatCount: 100,
        lungeCount: 50,
        walkSteps: 10000,
        runDistance: 5.0,
        date: DateTime.now(),
      );

      final score = ScoringConfig.calculateOverallScore(workout);

      // (100 * 1.2) + (50 * 1.2) + (10000 * 0.01) + (5.0 * 150)
      // = 120 + 60 + 100 + 750 = 1030
      expect(score, equals(1030.0));
    });

    test('Progress calculation is consistent', () {
      final goals = {
        'squat': 100,
        'lunge': 100,
        'walk': 10000,
        'run': 5.0,
      };

      final fullWorkout = WorkoutModel(
        userId: 'test-user',
        squatCount: 100,
        lungeCount: 100,
        walkSteps: 10000,
        runDistance: 5.0,
        date: DateTime.now(),
      );

      final totalProgress = ScoringConfig.calculateTotalProgress(
        fullWorkout,
        goals,
      );

      // 모든 목표 달성 시 진행률이 높아야 함
      expect(totalProgress, greaterThan(0.8));
    });
  });
}
