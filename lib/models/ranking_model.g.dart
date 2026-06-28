// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RankingModelImpl _$$RankingModelImplFromJson(Map<String, dynamic> json) =>
    _$RankingModelImpl(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      squatCount: (json['squatCount'] as num?)?.toInt() ?? 0,
      lungeCount: (json['lungeCount'] as num?)?.toInt() ?? 0,
      walkSteps: (json['walkSteps'] as num?)?.toInt() ?? 0,
      runDistance: (json['runDistance'] as num?)?.toDouble() ?? 0.0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      period: $enumDecodeNullable(_$RankingPeriodEnumMap, json['period']),
      category: $enumDecodeNullable(_$RankingCategoryEnumMap, json['category']),
    );

Map<String, dynamic> _$$RankingModelImplToJson(_$RankingModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'overallScore': instance.overallScore,
      'squatCount': instance.squatCount,
      'lungeCount': instance.lungeCount,
      'walkSteps': instance.walkSteps,
      'runDistance': instance.runDistance,
      'rank': instance.rank,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
      'period': _$RankingPeriodEnumMap[instance.period],
      'category': _$RankingCategoryEnumMap[instance.category],
    };

const _$RankingPeriodEnumMap = {
  RankingPeriod.daily: 'daily',
  RankingPeriod.weekly: 'weekly',
  RankingPeriod.monthly: 'monthly',
  RankingPeriod.allTime: 'allTime',
};

const _$RankingCategoryEnumMap = {
  RankingCategory.overall: 'overall',
  RankingCategory.squats: 'squats',
  RankingCategory.lunges: 'lunges',
  RankingCategory.walking: 'walking',
  RankingCategory.running: 'running',
};

_$UserRankingStatsImpl _$$UserRankingStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$UserRankingStatsImpl(
      userId: json['userId'] as String? ?? '',
      overallRankDaily: (json['overallRankDaily'] as num?)?.toInt() ?? 0,
      overallRankWeekly: (json['overallRankWeekly'] as num?)?.toInt() ?? 0,
      overallRankMonthly: (json['overallRankMonthly'] as num?)?.toInt() ?? 0,
      overallRankAllTime: (json['overallRankAllTime'] as num?)?.toInt() ?? 0,
      squatRankDaily: (json['squatRankDaily'] as num?)?.toInt() ?? 0,
      squatRankWeekly: (json['squatRankWeekly'] as num?)?.toInt() ?? 0,
      squatRankMonthly: (json['squatRankMonthly'] as num?)?.toInt() ?? 0,
      squatRankAllTime: (json['squatRankAllTime'] as num?)?.toInt() ?? 0,
      lungeRankDaily: (json['lungeRankDaily'] as num?)?.toInt() ?? 0,
      lungeRankWeekly: (json['lungeRankWeekly'] as num?)?.toInt() ?? 0,
      lungeRankMonthly: (json['lungeRankMonthly'] as num?)?.toInt() ?? 0,
      lungeRankAllTime: (json['lungeRankAllTime'] as num?)?.toInt() ?? 0,
      walkRankDaily: (json['walkRankDaily'] as num?)?.toInt() ?? 0,
      walkRankWeekly: (json['walkRankWeekly'] as num?)?.toInt() ?? 0,
      walkRankMonthly: (json['walkRankMonthly'] as num?)?.toInt() ?? 0,
      walkRankAllTime: (json['walkRankAllTime'] as num?)?.toInt() ?? 0,
      runRankDaily: (json['runRankDaily'] as num?)?.toInt() ?? 0,
      runRankWeekly: (json['runRankWeekly'] as num?)?.toInt() ?? 0,
      runRankMonthly: (json['runRankMonthly'] as num?)?.toInt() ?? 0,
      runRankAllTime: (json['runRankAllTime'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$UserRankingStatsImplToJson(
        _$UserRankingStatsImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'overallRankDaily': instance.overallRankDaily,
      'overallRankWeekly': instance.overallRankWeekly,
      'overallRankMonthly': instance.overallRankMonthly,
      'overallRankAllTime': instance.overallRankAllTime,
      'squatRankDaily': instance.squatRankDaily,
      'squatRankWeekly': instance.squatRankWeekly,
      'squatRankMonthly': instance.squatRankMonthly,
      'squatRankAllTime': instance.squatRankAllTime,
      'lungeRankDaily': instance.lungeRankDaily,
      'lungeRankWeekly': instance.lungeRankWeekly,
      'lungeRankMonthly': instance.lungeRankMonthly,
      'lungeRankAllTime': instance.lungeRankAllTime,
      'walkRankDaily': instance.walkRankDaily,
      'walkRankWeekly': instance.walkRankWeekly,
      'walkRankMonthly': instance.walkRankMonthly,
      'walkRankAllTime': instance.walkRankAllTime,
      'runRankDaily': instance.runRankDaily,
      'runRankWeekly': instance.runRankWeekly,
      'runRankMonthly': instance.runRankMonthly,
      'runRankAllTime': instance.runRankAllTime,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
