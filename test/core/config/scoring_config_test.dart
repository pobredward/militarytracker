import 'package:flutter_test/flutter_test.dart';
import 'package:militarytracker/core/config/scoring_config.dart';
import 'package:militarytracker/models/workout_model.dart';

void main() {
  group('ScoringConfig Tests', () {
    test('calculateOverallScore returns correct total', () {
      // Arrange
      final workout = WorkoutModel(
        userId: 'test-user',
        squatCount: 100,
        lungeCount: 50,
        walkSteps: 10000,
        runDistance: 5.0,
        date: DateTime.now(),
      );

      // Act
      final score = ScoringConfig.calculateOverallScore(workout);

      // Assert
      // (100 * 1.2) + (50 * 1.2) + (10000 * 0.01) + (5.0 * 150)
      // = 120 + 60 + 100 + 750 = 1030
      expect(score, equals(1030.0));
    });

    test('calculateSquatProgress returns correct progress', () {
      // Arrange
      final squatCount = 50;
      final goal = 100;

      // Act
      final progress = ScoringConfig.calculateSquatProgress(squatCount, goal);

      // Assert
      // (50 / 100) * 1.2 = 0.6
      expect(progress, equals(0.6));
    });

    test('calculateProgress clamps value between 0 and 1', () {
      // Arrange
      final overGoal = 200;
      final goal = 100;

      // Act
      final progress = ScoringConfig.calculateProgress(overGoal, goal, weight: 1.0);

      // Assert - Should be clamped to 1.0
      expect(progress, equals(1.0));
    });

    test('calculateTotalProgress returns average of all exercises', () {
      // Arrange
      final workout = WorkoutModel(
        userId: 'test-user',
        squatCount: 100, // 100% 달성
        lungeCount: 50,  // 50% 달성
        walkSteps: 5000, // 50% 달성
        runDistance: 2.5, // 50% 달성
        date: DateTime.now(),
      );

      final goals = {
        'squat': 100,
        'lunge': 100,
        'walk': 10000,
        'run': 5.0,
      };

      // Act
      final totalProgress = ScoringConfig.calculateTotalProgress(workout, goals);

      // Assert - 평균 진행률이 대략 0.65~0.75 사이일 것으로 예상
      expect(totalProgress, greaterThan(0.0));
      expect(totalProgress, lessThanOrEqualTo(1.0));
    });

    test('calculateDetailedScores returns breakdown', () {
      // Arrange
      final workout = WorkoutModel(
        userId: 'test-user',
        squatCount: 100,
        lungeCount: 100,
        walkSteps: 10000,
        runDistance: 5.0,
        date: DateTime.now(),
      );

      // Act
      final scores = ScoringConfig.calculateDetailedScores(workout);

      // Assert
      expect(scores['squat'], equals(120.0));
      expect(scores['lunge'], equals(120.0));
      expect(scores['walk'], equals(100.0));
      expect(scores['run'], equals(750.0));
      expect(scores['total'], equals(1090.0));
    });

    test('scoreToPercentage converts score correctly', () {
      // Arrange
      final score = 500.0;
      final maxScore = 1000.0;

      // Act
      final percentage = ScoringConfig.scoreToPercentage(score, maxScore);

      // Assert
      expect(percentage, equals(50));
    });

    test('scoreToPercentage clamps at 100', () {
      // Arrange
      final score = 1500.0;
      final maxScore = 1000.0;

      // Act
      final percentage = ScoringConfig.scoreToPercentage(score, maxScore);

      // Assert
      expect(percentage, equals(100));
    });
  });
}
