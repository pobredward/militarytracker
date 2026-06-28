import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_model.freezed.dart';
part 'ranking_model.g.dart';

enum RankingPeriod {
  daily,   // 일간
  weekly,  // 주간
  monthly, // 월간
  allTime, // 전체
}

enum RankingCategory {
  overall,  // 종합
  squats,   // 스쿼트
  lunges,   // 런지
  walking,  // 걷기
  running,  // 뛰기
}

@freezed
class RankingModel with _$RankingModel {
  const factory RankingModel({
    @Default('') String userId,
    @Default('') String displayName,
    String? photoUrl,
    @Default(0.0) double overallScore,  // 종합 점수
    @Default(0) int squatCount,
    @Default(0) int lungeCount,
    @Default(0) int walkSteps,
    @Default(0.0) double runDistance,
    @Default(0) int rank,  // 순위
    DateTime? lastUpdated,
    // 기간별 구분을 위한 필드
    RankingPeriod? period,
    RankingCategory? category,
  }) = _RankingModel;

  factory RankingModel.fromJson(Map<String, dynamic> json) =>
      _$RankingModelFromJson(json);
}

// 종합 점수 계산 로직
extension RankingScoreCalculator on RankingModel {
  /// 종합 점수를 계산합니다.
  /// 
  /// 가중치:
  /// - 스쿼트: 1.2 (1회당 1.2점)
  /// - 런지: 1.2 (1회당 1.2점)
  /// - 걷기: 0.01 (100보당 1점)
  /// - 뛰기: 150 (1km당 150점)
  double calculateOverallScore() {
    final squatScore = squatCount * 1.2;
    final lungeScore = lungeCount * 1.2;
    final walkScore = walkSteps * 0.01;
    final runScore = runDistance * 150;
    
    return squatScore + lungeScore + walkScore + runScore;
  }

  /// 특정 카테고리의 점수를 반환합니다.
  double getScoreForCategory(RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return calculateOverallScore();
      case RankingCategory.squats:
        return squatCount.toDouble();
      case RankingCategory.lunges:
        return lungeCount.toDouble();
      case RankingCategory.walking:
        return walkSteps.toDouble();
      case RankingCategory.running:
        return runDistance;
    }
  }
}

/// 사용자의 랭킹 통계
@freezed
class UserRankingStats with _$UserRankingStats {
  const factory UserRankingStats({
    @Default('') String userId,
    // 종합 랭킹
    @Default(0) int overallRankDaily,
    @Default(0) int overallRankWeekly,
    @Default(0) int overallRankMonthly,
    @Default(0) int overallRankAllTime,
    // 스쿼트 랭킹
    @Default(0) int squatRankDaily,
    @Default(0) int squatRankWeekly,
    @Default(0) int squatRankMonthly,
    @Default(0) int squatRankAllTime,
    // 런지 랭킹
    @Default(0) int lungeRankDaily,
    @Default(0) int lungeRankWeekly,
    @Default(0) int lungeRankMonthly,
    @Default(0) int lungeRankAllTime,
    // 걷기 랭킹
    @Default(0) int walkRankDaily,
    @Default(0) int walkRankWeekly,
    @Default(0) int walkRankMonthly,
    @Default(0) int walkRankAllTime,
    // 뛰기 랭킹
    @Default(0) int runRankDaily,
    @Default(0) int runRankWeekly,
    @Default(0) int runRankMonthly,
    @Default(0) int runRankAllTime,
    DateTime? lastUpdated,
  }) = _UserRankingStats;

  factory UserRankingStats.fromJson(Map<String, dynamic> json) =>
      _$UserRankingStatsFromJson(json);
}
