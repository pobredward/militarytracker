import '../../models/workout_model.dart';

/// 운동 점수 및 가중치 설정
/// 
/// 이 클래스는 운동별 가중치와 점수 계산 로직을 중앙에서 관리합니다.
/// 하드코딩된 매직 넘버를 제거하고 일관성 있는 점수 계산을 제공합니다.
class ScoringConfig {
  // Private constructor to prevent instantiation
  ScoringConfig._();

  // ==================== 가중치 상수 ====================
  
  /// 스쿼트 가중치 (1회당 점수)
  static const double squatWeight = 1.2;
  
  /// 런지 가중치 (1회당 점수)
  static const double lungeWeight = 1.2;
  
  /// 걷기 가중치 (1걸음당 점수)
  static const double walkWeight = 0.01;
  
  /// 달리기 점수 배율 (1km당 점수)
  static const double runScoreMultiplier = 150.0;
  
  /// 진행률 계산용 가중치
  static const double progressWeight = 1.0;

  // ==================== 점수 계산 메서드 ====================
  
  /// 종합 점수 계산
  /// 
  /// 모든 운동 종목의 점수를 합산하여 종합 점수를 반환합니다.
  /// 
  /// Parameters:
  ///   - [workout]: 점수를 계산할 운동 모델
  /// 
  /// Returns:
  ///   종합 점수 (double)
  static double calculateOverallScore(WorkoutModel workout) {
    final squatScore = workout.squatCount * squatWeight;
    final lungeScore = workout.lungeCount * lungeWeight;
    final walkScore = workout.walkSteps * walkWeight;
    final runScore = workout.runDistance * runScoreMultiplier;
    
    return squatScore + lungeScore + walkScore + runScore;
  }
  
  /// 개별 운동별 점수 계산
  /// 
  /// Returns:
  ///   각 운동별 점수를 담은 Map
  static Map<String, double> calculateDetailedScores(WorkoutModel workout) {
    return {
      'squat': workout.squatCount * squatWeight,
      'lunge': workout.lungeCount * lungeWeight,
      'walk': workout.walkSteps * walkWeight,
      'run': workout.runDistance * runScoreMultiplier,
      'total': calculateOverallScore(workout),
    };
  }
  
  /// 목표 대비 진행률 계산
  /// 
  /// Parameters:
  ///   - [current]: 현재 값
  ///   - [goal]: 목표 값
  ///   - [weight]: 가중치 (옵션, 기본값 1.0)
  /// 
  /// Returns:
  ///   0.0 ~ 1.0 사이의 진행률
  static double calculateProgress(
    num current,
    num goal, {
    double weight = progressWeight,
  }) {
    if (goal <= 0) return 0.0;
    return ((current / goal) * weight).clamp(0.0, 1.0);
  }
  
  /// 스쿼트 진행률 계산
  static double calculateSquatProgress(int count, int goal) {
    return calculateProgress(count, goal, weight: squatWeight);
  }
  
  /// 런지 진행률 계산
  static double calculateLungeProgress(int count, int goal) {
    return calculateProgress(count, goal, weight: lungeWeight);
  }
  
  /// 걷기 진행률 계산
  static double calculateWalkProgress(int steps, int goal) {
    return calculateProgress(steps, goal, weight: walkWeight * 100);
  }
  
  /// 달리기 진행률 계산
  static double calculateRunProgress(double distance, double goal) {
    return calculateProgress(distance, goal, weight: runScoreMultiplier / 100);
  }
  
  /// 전체 진행률 계산 (4개 운동의 평균)
  /// 
  /// Parameters:
  ///   - [workout]: 진행률을 계산할 운동 모델
  ///   - [goals]: 목표 값 Map {squat, lunge, walk, run}
  /// 
  /// Returns:
  ///   0.0 ~ 1.0 사이의 전체 진행률
  static double calculateTotalProgress(
    WorkoutModel workout,
    Map<String, num> goals,
  ) {
    final squatProgress = calculateSquatProgress(
      workout.squatCount,
      goals['squat']?.toInt() ?? 100,
    );
    final lungeProgress = calculateLungeProgress(
      workout.lungeCount,
      goals['lunge']?.toInt() ?? 100,
    );
    final walkProgress = calculateWalkProgress(
      workout.walkSteps,
      goals['walk']?.toInt() ?? 10000,
    );
    final runProgress = calculateRunProgress(
      workout.runDistance,
      goals['run']?.toDouble() ?? 5.0,
    );
    
    return (squatProgress + lungeProgress + walkProgress + runProgress) / 4;
  }

  // ==================== 최대 점수 계산 ====================
  
  /// 목표 달성 시 최대 점수
  /// 
  /// Parameters:
  ///   - [goals]: 목표 값 Map
  /// 
  /// Returns:
  ///   목표 달성 시 얻을 수 있는 최대 점수
  static double calculateMaxScore(Map<String, num> goals) {
    final squatMaxScore = (goals['squat']?.toInt() ?? 100) * squatWeight;
    final lungeMaxScore = (goals['lunge']?.toInt() ?? 100) * lungeWeight;
    final walkMaxScore = (goals['walk']?.toInt() ?? 10000) * walkWeight;
    final runMaxScore = (goals['run']?.toDouble() ?? 5.0) * runScoreMultiplier;
    
    return squatMaxScore + lungeMaxScore + walkMaxScore + runMaxScore;
  }
  
  /// 점수를 퍼센트로 변환
  /// 
  /// Parameters:
  ///   - [score]: 현재 점수
  ///   - [maxScore]: 최대 점수
  /// 
  /// Returns:
  ///   0 ~ 100 사이의 퍼센트 값
  static int scoreToPercentage(double score, double maxScore) {
    if (maxScore <= 0) return 0;
    return ((score / maxScore) * 100).clamp(0, 100).toInt();
  }
}
