// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RankingModel _$RankingModelFromJson(Map<String, dynamic> json) {
  return _RankingModel.fromJson(json);
}

/// @nodoc
mixin _$RankingModel {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  double get overallScore => throw _privateConstructorUsedError; // 종합 점수
  int get squatCount => throw _privateConstructorUsedError;
  int get lungeCount => throw _privateConstructorUsedError;
  int get walkSteps => throw _privateConstructorUsedError;
  double get runDistance => throw _privateConstructorUsedError;
  int get rank => throw _privateConstructorUsedError; // 순위
  DateTime? get lastUpdated =>
      throw _privateConstructorUsedError; // 기간별 구분을 위한 필드
  RankingPeriod? get period => throw _privateConstructorUsedError;
  RankingCategory? get category => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RankingModelCopyWith<RankingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankingModelCopyWith<$Res> {
  factory $RankingModelCopyWith(
          RankingModel value, $Res Function(RankingModel) then) =
      _$RankingModelCopyWithImpl<$Res, RankingModel>;
  @useResult
  $Res call(
      {String userId,
      String displayName,
      String? photoUrl,
      double overallScore,
      int squatCount,
      int lungeCount,
      int walkSteps,
      double runDistance,
      int rank,
      DateTime? lastUpdated,
      RankingPeriod? period,
      RankingCategory? category});
}

/// @nodoc
class _$RankingModelCopyWithImpl<$Res, $Val extends RankingModel>
    implements $RankingModelCopyWith<$Res> {
  _$RankingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? photoUrl = freezed,
    Object? overallScore = null,
    Object? squatCount = null,
    Object? lungeCount = null,
    Object? walkSteps = null,
    Object? runDistance = null,
    Object? rank = null,
    Object? lastUpdated = freezed,
    Object? period = freezed,
    Object? category = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      overallScore: null == overallScore
          ? _value.overallScore
          : overallScore // ignore: cast_nullable_to_non_nullable
              as double,
      squatCount: null == squatCount
          ? _value.squatCount
          : squatCount // ignore: cast_nullable_to_non_nullable
              as int,
      lungeCount: null == lungeCount
          ? _value.lungeCount
          : lungeCount // ignore: cast_nullable_to_non_nullable
              as int,
      walkSteps: null == walkSteps
          ? _value.walkSteps
          : walkSteps // ignore: cast_nullable_to_non_nullable
              as int,
      runDistance: null == runDistance
          ? _value.runDistance
          : runDistance // ignore: cast_nullable_to_non_nullable
              as double,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      period: freezed == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as RankingPeriod?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as RankingCategory?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankingModelImplCopyWith<$Res>
    implements $RankingModelCopyWith<$Res> {
  factory _$$RankingModelImplCopyWith(
          _$RankingModelImpl value, $Res Function(_$RankingModelImpl) then) =
      __$$RankingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String displayName,
      String? photoUrl,
      double overallScore,
      int squatCount,
      int lungeCount,
      int walkSteps,
      double runDistance,
      int rank,
      DateTime? lastUpdated,
      RankingPeriod? period,
      RankingCategory? category});
}

/// @nodoc
class __$$RankingModelImplCopyWithImpl<$Res>
    extends _$RankingModelCopyWithImpl<$Res, _$RankingModelImpl>
    implements _$$RankingModelImplCopyWith<$Res> {
  __$$RankingModelImplCopyWithImpl(
      _$RankingModelImpl _value, $Res Function(_$RankingModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? photoUrl = freezed,
    Object? overallScore = null,
    Object? squatCount = null,
    Object? lungeCount = null,
    Object? walkSteps = null,
    Object? runDistance = null,
    Object? rank = null,
    Object? lastUpdated = freezed,
    Object? period = freezed,
    Object? category = freezed,
  }) {
    return _then(_$RankingModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      overallScore: null == overallScore
          ? _value.overallScore
          : overallScore // ignore: cast_nullable_to_non_nullable
              as double,
      squatCount: null == squatCount
          ? _value.squatCount
          : squatCount // ignore: cast_nullable_to_non_nullable
              as int,
      lungeCount: null == lungeCount
          ? _value.lungeCount
          : lungeCount // ignore: cast_nullable_to_non_nullable
              as int,
      walkSteps: null == walkSteps
          ? _value.walkSteps
          : walkSteps // ignore: cast_nullable_to_non_nullable
              as int,
      runDistance: null == runDistance
          ? _value.runDistance
          : runDistance // ignore: cast_nullable_to_non_nullable
              as double,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      period: freezed == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as RankingPeriod?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as RankingCategory?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RankingModelImpl implements _RankingModel {
  const _$RankingModelImpl(
      {this.userId = '',
      this.displayName = '',
      this.photoUrl,
      this.overallScore = 0.0,
      this.squatCount = 0,
      this.lungeCount = 0,
      this.walkSteps = 0,
      this.runDistance = 0.0,
      this.rank = 0,
      this.lastUpdated,
      this.period,
      this.category});

  factory _$RankingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RankingModelImplFromJson(json);

  @override
  @JsonKey()
  final String userId;
  @override
  @JsonKey()
  final String displayName;
  @override
  final String? photoUrl;
  @override
  @JsonKey()
  final double overallScore;
// 종합 점수
  @override
  @JsonKey()
  final int squatCount;
  @override
  @JsonKey()
  final int lungeCount;
  @override
  @JsonKey()
  final int walkSteps;
  @override
  @JsonKey()
  final double runDistance;
  @override
  @JsonKey()
  final int rank;
// 순위
  @override
  final DateTime? lastUpdated;
// 기간별 구분을 위한 필드
  @override
  final RankingPeriod? period;
  @override
  final RankingCategory? category;

  @override
  String toString() {
    return 'RankingModel(userId: $userId, displayName: $displayName, photoUrl: $photoUrl, overallScore: $overallScore, squatCount: $squatCount, lungeCount: $lungeCount, walkSteps: $walkSteps, runDistance: $runDistance, rank: $rank, lastUpdated: $lastUpdated, period: $period, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankingModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.overallScore, overallScore) ||
                other.overallScore == overallScore) &&
            (identical(other.squatCount, squatCount) ||
                other.squatCount == squatCount) &&
            (identical(other.lungeCount, lungeCount) ||
                other.lungeCount == lungeCount) &&
            (identical(other.walkSteps, walkSteps) ||
                other.walkSteps == walkSteps) &&
            (identical(other.runDistance, runDistance) ||
                other.runDistance == runDistance) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      displayName,
      photoUrl,
      overallScore,
      squatCount,
      lungeCount,
      walkSteps,
      runDistance,
      rank,
      lastUpdated,
      period,
      category);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RankingModelImplCopyWith<_$RankingModelImpl> get copyWith =>
      __$$RankingModelImplCopyWithImpl<_$RankingModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RankingModelImplToJson(
      this,
    );
  }
}

abstract class _RankingModel implements RankingModel {
  const factory _RankingModel(
      {final String userId,
      final String displayName,
      final String? photoUrl,
      final double overallScore,
      final int squatCount,
      final int lungeCount,
      final int walkSteps,
      final double runDistance,
      final int rank,
      final DateTime? lastUpdated,
      final RankingPeriod? period,
      final RankingCategory? category}) = _$RankingModelImpl;

  factory _RankingModel.fromJson(Map<String, dynamic> json) =
      _$RankingModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  String? get photoUrl;
  @override
  double get overallScore;
  @override // 종합 점수
  int get squatCount;
  @override
  int get lungeCount;
  @override
  int get walkSteps;
  @override
  double get runDistance;
  @override
  int get rank;
  @override // 순위
  DateTime? get lastUpdated;
  @override // 기간별 구분을 위한 필드
  RankingPeriod? get period;
  @override
  RankingCategory? get category;
  @override
  @JsonKey(ignore: true)
  _$$RankingModelImplCopyWith<_$RankingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserRankingStats _$UserRankingStatsFromJson(Map<String, dynamic> json) {
  return _UserRankingStats.fromJson(json);
}

/// @nodoc
mixin _$UserRankingStats {
  String get userId => throw _privateConstructorUsedError; // 종합 랭킹
  int get overallRankDaily => throw _privateConstructorUsedError;
  int get overallRankWeekly => throw _privateConstructorUsedError;
  int get overallRankMonthly => throw _privateConstructorUsedError;
  int get overallRankAllTime => throw _privateConstructorUsedError; // 스쿼트 랭킹
  int get squatRankDaily => throw _privateConstructorUsedError;
  int get squatRankWeekly => throw _privateConstructorUsedError;
  int get squatRankMonthly => throw _privateConstructorUsedError;
  int get squatRankAllTime => throw _privateConstructorUsedError; // 런지 랭킹
  int get lungeRankDaily => throw _privateConstructorUsedError;
  int get lungeRankWeekly => throw _privateConstructorUsedError;
  int get lungeRankMonthly => throw _privateConstructorUsedError;
  int get lungeRankAllTime => throw _privateConstructorUsedError; // 걷기 랭킹
  int get walkRankDaily => throw _privateConstructorUsedError;
  int get walkRankWeekly => throw _privateConstructorUsedError;
  int get walkRankMonthly => throw _privateConstructorUsedError;
  int get walkRankAllTime => throw _privateConstructorUsedError; // 뛰기 랭킹
  int get runRankDaily => throw _privateConstructorUsedError;
  int get runRankWeekly => throw _privateConstructorUsedError;
  int get runRankMonthly => throw _privateConstructorUsedError;
  int get runRankAllTime => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserRankingStatsCopyWith<UserRankingStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRankingStatsCopyWith<$Res> {
  factory $UserRankingStatsCopyWith(
          UserRankingStats value, $Res Function(UserRankingStats) then) =
      _$UserRankingStatsCopyWithImpl<$Res, UserRankingStats>;
  @useResult
  $Res call(
      {String userId,
      int overallRankDaily,
      int overallRankWeekly,
      int overallRankMonthly,
      int overallRankAllTime,
      int squatRankDaily,
      int squatRankWeekly,
      int squatRankMonthly,
      int squatRankAllTime,
      int lungeRankDaily,
      int lungeRankWeekly,
      int lungeRankMonthly,
      int lungeRankAllTime,
      int walkRankDaily,
      int walkRankWeekly,
      int walkRankMonthly,
      int walkRankAllTime,
      int runRankDaily,
      int runRankWeekly,
      int runRankMonthly,
      int runRankAllTime,
      DateTime? lastUpdated});
}

/// @nodoc
class _$UserRankingStatsCopyWithImpl<$Res, $Val extends UserRankingStats>
    implements $UserRankingStatsCopyWith<$Res> {
  _$UserRankingStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? overallRankDaily = null,
    Object? overallRankWeekly = null,
    Object? overallRankMonthly = null,
    Object? overallRankAllTime = null,
    Object? squatRankDaily = null,
    Object? squatRankWeekly = null,
    Object? squatRankMonthly = null,
    Object? squatRankAllTime = null,
    Object? lungeRankDaily = null,
    Object? lungeRankWeekly = null,
    Object? lungeRankMonthly = null,
    Object? lungeRankAllTime = null,
    Object? walkRankDaily = null,
    Object? walkRankWeekly = null,
    Object? walkRankMonthly = null,
    Object? walkRankAllTime = null,
    Object? runRankDaily = null,
    Object? runRankWeekly = null,
    Object? runRankMonthly = null,
    Object? runRankAllTime = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      overallRankDaily: null == overallRankDaily
          ? _value.overallRankDaily
          : overallRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      overallRankWeekly: null == overallRankWeekly
          ? _value.overallRankWeekly
          : overallRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      overallRankMonthly: null == overallRankMonthly
          ? _value.overallRankMonthly
          : overallRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      overallRankAllTime: null == overallRankAllTime
          ? _value.overallRankAllTime
          : overallRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankDaily: null == squatRankDaily
          ? _value.squatRankDaily
          : squatRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankWeekly: null == squatRankWeekly
          ? _value.squatRankWeekly
          : squatRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankMonthly: null == squatRankMonthly
          ? _value.squatRankMonthly
          : squatRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankAllTime: null == squatRankAllTime
          ? _value.squatRankAllTime
          : squatRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankDaily: null == lungeRankDaily
          ? _value.lungeRankDaily
          : lungeRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankWeekly: null == lungeRankWeekly
          ? _value.lungeRankWeekly
          : lungeRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankMonthly: null == lungeRankMonthly
          ? _value.lungeRankMonthly
          : lungeRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankAllTime: null == lungeRankAllTime
          ? _value.lungeRankAllTime
          : lungeRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankDaily: null == walkRankDaily
          ? _value.walkRankDaily
          : walkRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankWeekly: null == walkRankWeekly
          ? _value.walkRankWeekly
          : walkRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankMonthly: null == walkRankMonthly
          ? _value.walkRankMonthly
          : walkRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankAllTime: null == walkRankAllTime
          ? _value.walkRankAllTime
          : walkRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      runRankDaily: null == runRankDaily
          ? _value.runRankDaily
          : runRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      runRankWeekly: null == runRankWeekly
          ? _value.runRankWeekly
          : runRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      runRankMonthly: null == runRankMonthly
          ? _value.runRankMonthly
          : runRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      runRankAllTime: null == runRankAllTime
          ? _value.runRankAllTime
          : runRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserRankingStatsImplCopyWith<$Res>
    implements $UserRankingStatsCopyWith<$Res> {
  factory _$$UserRankingStatsImplCopyWith(_$UserRankingStatsImpl value,
          $Res Function(_$UserRankingStatsImpl) then) =
      __$$UserRankingStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      int overallRankDaily,
      int overallRankWeekly,
      int overallRankMonthly,
      int overallRankAllTime,
      int squatRankDaily,
      int squatRankWeekly,
      int squatRankMonthly,
      int squatRankAllTime,
      int lungeRankDaily,
      int lungeRankWeekly,
      int lungeRankMonthly,
      int lungeRankAllTime,
      int walkRankDaily,
      int walkRankWeekly,
      int walkRankMonthly,
      int walkRankAllTime,
      int runRankDaily,
      int runRankWeekly,
      int runRankMonthly,
      int runRankAllTime,
      DateTime? lastUpdated});
}

/// @nodoc
class __$$UserRankingStatsImplCopyWithImpl<$Res>
    extends _$UserRankingStatsCopyWithImpl<$Res, _$UserRankingStatsImpl>
    implements _$$UserRankingStatsImplCopyWith<$Res> {
  __$$UserRankingStatsImplCopyWithImpl(_$UserRankingStatsImpl _value,
      $Res Function(_$UserRankingStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? overallRankDaily = null,
    Object? overallRankWeekly = null,
    Object? overallRankMonthly = null,
    Object? overallRankAllTime = null,
    Object? squatRankDaily = null,
    Object? squatRankWeekly = null,
    Object? squatRankMonthly = null,
    Object? squatRankAllTime = null,
    Object? lungeRankDaily = null,
    Object? lungeRankWeekly = null,
    Object? lungeRankMonthly = null,
    Object? lungeRankAllTime = null,
    Object? walkRankDaily = null,
    Object? walkRankWeekly = null,
    Object? walkRankMonthly = null,
    Object? walkRankAllTime = null,
    Object? runRankDaily = null,
    Object? runRankWeekly = null,
    Object? runRankMonthly = null,
    Object? runRankAllTime = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$UserRankingStatsImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      overallRankDaily: null == overallRankDaily
          ? _value.overallRankDaily
          : overallRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      overallRankWeekly: null == overallRankWeekly
          ? _value.overallRankWeekly
          : overallRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      overallRankMonthly: null == overallRankMonthly
          ? _value.overallRankMonthly
          : overallRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      overallRankAllTime: null == overallRankAllTime
          ? _value.overallRankAllTime
          : overallRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankDaily: null == squatRankDaily
          ? _value.squatRankDaily
          : squatRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankWeekly: null == squatRankWeekly
          ? _value.squatRankWeekly
          : squatRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankMonthly: null == squatRankMonthly
          ? _value.squatRankMonthly
          : squatRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      squatRankAllTime: null == squatRankAllTime
          ? _value.squatRankAllTime
          : squatRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankDaily: null == lungeRankDaily
          ? _value.lungeRankDaily
          : lungeRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankWeekly: null == lungeRankWeekly
          ? _value.lungeRankWeekly
          : lungeRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankMonthly: null == lungeRankMonthly
          ? _value.lungeRankMonthly
          : lungeRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      lungeRankAllTime: null == lungeRankAllTime
          ? _value.lungeRankAllTime
          : lungeRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankDaily: null == walkRankDaily
          ? _value.walkRankDaily
          : walkRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankWeekly: null == walkRankWeekly
          ? _value.walkRankWeekly
          : walkRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankMonthly: null == walkRankMonthly
          ? _value.walkRankMonthly
          : walkRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      walkRankAllTime: null == walkRankAllTime
          ? _value.walkRankAllTime
          : walkRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      runRankDaily: null == runRankDaily
          ? _value.runRankDaily
          : runRankDaily // ignore: cast_nullable_to_non_nullable
              as int,
      runRankWeekly: null == runRankWeekly
          ? _value.runRankWeekly
          : runRankWeekly // ignore: cast_nullable_to_non_nullable
              as int,
      runRankMonthly: null == runRankMonthly
          ? _value.runRankMonthly
          : runRankMonthly // ignore: cast_nullable_to_non_nullable
              as int,
      runRankAllTime: null == runRankAllTime
          ? _value.runRankAllTime
          : runRankAllTime // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserRankingStatsImpl implements _UserRankingStats {
  const _$UserRankingStatsImpl(
      {this.userId = '',
      this.overallRankDaily = 0,
      this.overallRankWeekly = 0,
      this.overallRankMonthly = 0,
      this.overallRankAllTime = 0,
      this.squatRankDaily = 0,
      this.squatRankWeekly = 0,
      this.squatRankMonthly = 0,
      this.squatRankAllTime = 0,
      this.lungeRankDaily = 0,
      this.lungeRankWeekly = 0,
      this.lungeRankMonthly = 0,
      this.lungeRankAllTime = 0,
      this.walkRankDaily = 0,
      this.walkRankWeekly = 0,
      this.walkRankMonthly = 0,
      this.walkRankAllTime = 0,
      this.runRankDaily = 0,
      this.runRankWeekly = 0,
      this.runRankMonthly = 0,
      this.runRankAllTime = 0,
      this.lastUpdated});

  factory _$UserRankingStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRankingStatsImplFromJson(json);

  @override
  @JsonKey()
  final String userId;
// 종합 랭킹
  @override
  @JsonKey()
  final int overallRankDaily;
  @override
  @JsonKey()
  final int overallRankWeekly;
  @override
  @JsonKey()
  final int overallRankMonthly;
  @override
  @JsonKey()
  final int overallRankAllTime;
// 스쿼트 랭킹
  @override
  @JsonKey()
  final int squatRankDaily;
  @override
  @JsonKey()
  final int squatRankWeekly;
  @override
  @JsonKey()
  final int squatRankMonthly;
  @override
  @JsonKey()
  final int squatRankAllTime;
// 런지 랭킹
  @override
  @JsonKey()
  final int lungeRankDaily;
  @override
  @JsonKey()
  final int lungeRankWeekly;
  @override
  @JsonKey()
  final int lungeRankMonthly;
  @override
  @JsonKey()
  final int lungeRankAllTime;
// 걷기 랭킹
  @override
  @JsonKey()
  final int walkRankDaily;
  @override
  @JsonKey()
  final int walkRankWeekly;
  @override
  @JsonKey()
  final int walkRankMonthly;
  @override
  @JsonKey()
  final int walkRankAllTime;
// 뛰기 랭킹
  @override
  @JsonKey()
  final int runRankDaily;
  @override
  @JsonKey()
  final int runRankWeekly;
  @override
  @JsonKey()
  final int runRankMonthly;
  @override
  @JsonKey()
  final int runRankAllTime;
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'UserRankingStats(userId: $userId, overallRankDaily: $overallRankDaily, overallRankWeekly: $overallRankWeekly, overallRankMonthly: $overallRankMonthly, overallRankAllTime: $overallRankAllTime, squatRankDaily: $squatRankDaily, squatRankWeekly: $squatRankWeekly, squatRankMonthly: $squatRankMonthly, squatRankAllTime: $squatRankAllTime, lungeRankDaily: $lungeRankDaily, lungeRankWeekly: $lungeRankWeekly, lungeRankMonthly: $lungeRankMonthly, lungeRankAllTime: $lungeRankAllTime, walkRankDaily: $walkRankDaily, walkRankWeekly: $walkRankWeekly, walkRankMonthly: $walkRankMonthly, walkRankAllTime: $walkRankAllTime, runRankDaily: $runRankDaily, runRankWeekly: $runRankWeekly, runRankMonthly: $runRankMonthly, runRankAllTime: $runRankAllTime, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRankingStatsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.overallRankDaily, overallRankDaily) ||
                other.overallRankDaily == overallRankDaily) &&
            (identical(other.overallRankWeekly, overallRankWeekly) ||
                other.overallRankWeekly == overallRankWeekly) &&
            (identical(other.overallRankMonthly, overallRankMonthly) ||
                other.overallRankMonthly == overallRankMonthly) &&
            (identical(other.overallRankAllTime, overallRankAllTime) ||
                other.overallRankAllTime == overallRankAllTime) &&
            (identical(other.squatRankDaily, squatRankDaily) ||
                other.squatRankDaily == squatRankDaily) &&
            (identical(other.squatRankWeekly, squatRankWeekly) ||
                other.squatRankWeekly == squatRankWeekly) &&
            (identical(other.squatRankMonthly, squatRankMonthly) ||
                other.squatRankMonthly == squatRankMonthly) &&
            (identical(other.squatRankAllTime, squatRankAllTime) ||
                other.squatRankAllTime == squatRankAllTime) &&
            (identical(other.lungeRankDaily, lungeRankDaily) ||
                other.lungeRankDaily == lungeRankDaily) &&
            (identical(other.lungeRankWeekly, lungeRankWeekly) ||
                other.lungeRankWeekly == lungeRankWeekly) &&
            (identical(other.lungeRankMonthly, lungeRankMonthly) ||
                other.lungeRankMonthly == lungeRankMonthly) &&
            (identical(other.lungeRankAllTime, lungeRankAllTime) ||
                other.lungeRankAllTime == lungeRankAllTime) &&
            (identical(other.walkRankDaily, walkRankDaily) ||
                other.walkRankDaily == walkRankDaily) &&
            (identical(other.walkRankWeekly, walkRankWeekly) ||
                other.walkRankWeekly == walkRankWeekly) &&
            (identical(other.walkRankMonthly, walkRankMonthly) ||
                other.walkRankMonthly == walkRankMonthly) &&
            (identical(other.walkRankAllTime, walkRankAllTime) ||
                other.walkRankAllTime == walkRankAllTime) &&
            (identical(other.runRankDaily, runRankDaily) ||
                other.runRankDaily == runRankDaily) &&
            (identical(other.runRankWeekly, runRankWeekly) ||
                other.runRankWeekly == runRankWeekly) &&
            (identical(other.runRankMonthly, runRankMonthly) ||
                other.runRankMonthly == runRankMonthly) &&
            (identical(other.runRankAllTime, runRankAllTime) ||
                other.runRankAllTime == runRankAllTime) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        userId,
        overallRankDaily,
        overallRankWeekly,
        overallRankMonthly,
        overallRankAllTime,
        squatRankDaily,
        squatRankWeekly,
        squatRankMonthly,
        squatRankAllTime,
        lungeRankDaily,
        lungeRankWeekly,
        lungeRankMonthly,
        lungeRankAllTime,
        walkRankDaily,
        walkRankWeekly,
        walkRankMonthly,
        walkRankAllTime,
        runRankDaily,
        runRankWeekly,
        runRankMonthly,
        runRankAllTime,
        lastUpdated
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRankingStatsImplCopyWith<_$UserRankingStatsImpl> get copyWith =>
      __$$UserRankingStatsImplCopyWithImpl<_$UserRankingStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRankingStatsImplToJson(
      this,
    );
  }
}

abstract class _UserRankingStats implements UserRankingStats {
  const factory _UserRankingStats(
      {final String userId,
      final int overallRankDaily,
      final int overallRankWeekly,
      final int overallRankMonthly,
      final int overallRankAllTime,
      final int squatRankDaily,
      final int squatRankWeekly,
      final int squatRankMonthly,
      final int squatRankAllTime,
      final int lungeRankDaily,
      final int lungeRankWeekly,
      final int lungeRankMonthly,
      final int lungeRankAllTime,
      final int walkRankDaily,
      final int walkRankWeekly,
      final int walkRankMonthly,
      final int walkRankAllTime,
      final int runRankDaily,
      final int runRankWeekly,
      final int runRankMonthly,
      final int runRankAllTime,
      final DateTime? lastUpdated}) = _$UserRankingStatsImpl;

  factory _UserRankingStats.fromJson(Map<String, dynamic> json) =
      _$UserRankingStatsImpl.fromJson;

  @override
  String get userId;
  @override // 종합 랭킹
  int get overallRankDaily;
  @override
  int get overallRankWeekly;
  @override
  int get overallRankMonthly;
  @override
  int get overallRankAllTime;
  @override // 스쿼트 랭킹
  int get squatRankDaily;
  @override
  int get squatRankWeekly;
  @override
  int get squatRankMonthly;
  @override
  int get squatRankAllTime;
  @override // 런지 랭킹
  int get lungeRankDaily;
  @override
  int get lungeRankWeekly;
  @override
  int get lungeRankMonthly;
  @override
  int get lungeRankAllTime;
  @override // 걷기 랭킹
  int get walkRankDaily;
  @override
  int get walkRankWeekly;
  @override
  int get walkRankMonthly;
  @override
  int get walkRankAllTime;
  @override // 뛰기 랭킹
  int get runRankDaily;
  @override
  int get runRankWeekly;
  @override
  int get runRankMonthly;
  @override
  int get runRankAllTime;
  @override
  DateTime? get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$UserRankingStatsImplCopyWith<_$UserRankingStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
