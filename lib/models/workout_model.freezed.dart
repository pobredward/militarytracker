// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutModel _$WorkoutModelFromJson(Map<String, dynamic> json) {
  return _WorkoutModel.fromJson(json);
}

/// @nodoc
mixin _$WorkoutModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get squatCount => throw _privateConstructorUsedError;
  int get lungeCount => throw _privateConstructorUsedError;
  int get walkSteps => throw _privateConstructorUsedError;
  double get runDistance => throw _privateConstructorUsedError; // km
  int get duration => throw _privateConstructorUsedError; // seconds
  String? get notes => throw _privateConstructorUsedError;
  @DateTimeConverter()
  DateTime get date => throw _privateConstructorUsedError;
  @NullableDateTimeConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @NullableDateTimeConverter()
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // 추적 모드 (각 운동별) - 기본값 automatic
  TrackingMode get squatMode => throw _privateConstructorUsedError;
  TrackingMode get lungeMode => throw _privateConstructorUsedError;
  TrackingMode get walkMode => throw _privateConstructorUsedError;
  TrackingMode get runMode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutModelCopyWith<WorkoutModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutModelCopyWith<$Res> {
  factory $WorkoutModelCopyWith(
          WorkoutModel value, $Res Function(WorkoutModel) then) =
      _$WorkoutModelCopyWithImpl<$Res, WorkoutModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      int squatCount,
      int lungeCount,
      int walkSteps,
      double runDistance,
      int duration,
      String? notes,
      @DateTimeConverter() DateTime date,
      @NullableDateTimeConverter() DateTime? createdAt,
      @NullableDateTimeConverter() DateTime? updatedAt,
      TrackingMode squatMode,
      TrackingMode lungeMode,
      TrackingMode walkMode,
      TrackingMode runMode});
}

/// @nodoc
class _$WorkoutModelCopyWithImpl<$Res, $Val extends WorkoutModel>
    implements $WorkoutModelCopyWith<$Res> {
  _$WorkoutModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? squatCount = null,
    Object? lungeCount = null,
    Object? walkSteps = null,
    Object? runDistance = null,
    Object? duration = null,
    Object? notes = freezed,
    Object? date = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? squatMode = null,
    Object? lungeMode = null,
    Object? walkMode = null,
    Object? runMode = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
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
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      squatMode: null == squatMode
          ? _value.squatMode
          : squatMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
      lungeMode: null == lungeMode
          ? _value.lungeMode
          : lungeMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
      walkMode: null == walkMode
          ? _value.walkMode
          : walkMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
      runMode: null == runMode
          ? _value.runMode
          : runMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutModelImplCopyWith<$Res>
    implements $WorkoutModelCopyWith<$Res> {
  factory _$$WorkoutModelImplCopyWith(
          _$WorkoutModelImpl value, $Res Function(_$WorkoutModelImpl) then) =
      __$$WorkoutModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      int squatCount,
      int lungeCount,
      int walkSteps,
      double runDistance,
      int duration,
      String? notes,
      @DateTimeConverter() DateTime date,
      @NullableDateTimeConverter() DateTime? createdAt,
      @NullableDateTimeConverter() DateTime? updatedAt,
      TrackingMode squatMode,
      TrackingMode lungeMode,
      TrackingMode walkMode,
      TrackingMode runMode});
}

/// @nodoc
class __$$WorkoutModelImplCopyWithImpl<$Res>
    extends _$WorkoutModelCopyWithImpl<$Res, _$WorkoutModelImpl>
    implements _$$WorkoutModelImplCopyWith<$Res> {
  __$$WorkoutModelImplCopyWithImpl(
      _$WorkoutModelImpl _value, $Res Function(_$WorkoutModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? squatCount = null,
    Object? lungeCount = null,
    Object? walkSteps = null,
    Object? runDistance = null,
    Object? duration = null,
    Object? notes = freezed,
    Object? date = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? squatMode = null,
    Object? lungeMode = null,
    Object? walkMode = null,
    Object? runMode = null,
  }) {
    return _then(_$WorkoutModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
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
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      squatMode: null == squatMode
          ? _value.squatMode
          : squatMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
      lungeMode: null == lungeMode
          ? _value.lungeMode
          : lungeMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
      walkMode: null == walkMode
          ? _value.walkMode
          : walkMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
      runMode: null == runMode
          ? _value.runMode
          : runMode // ignore: cast_nullable_to_non_nullable
              as TrackingMode,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutModelImpl implements _WorkoutModel {
  const _$WorkoutModelImpl(
      {this.id = '',
      this.userId = '',
      this.squatCount = 0,
      this.lungeCount = 0,
      this.walkSteps = 0,
      this.runDistance = 0.0,
      this.duration = 0,
      this.notes,
      @DateTimeConverter() required this.date,
      @NullableDateTimeConverter() this.createdAt,
      @NullableDateTimeConverter() this.updatedAt,
      this.squatMode = TrackingMode.automatic,
      this.lungeMode = TrackingMode.automatic,
      this.walkMode = TrackingMode.automatic,
      this.runMode = TrackingMode.automatic});

  factory _$WorkoutModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutModelImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String userId;
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
// km
  @override
  @JsonKey()
  final int duration;
// seconds
  @override
  final String? notes;
  @override
  @DateTimeConverter()
  final DateTime date;
  @override
  @NullableDateTimeConverter()
  final DateTime? createdAt;
  @override
  @NullableDateTimeConverter()
  final DateTime? updatedAt;
// 추적 모드 (각 운동별) - 기본값 automatic
  @override
  @JsonKey()
  final TrackingMode squatMode;
  @override
  @JsonKey()
  final TrackingMode lungeMode;
  @override
  @JsonKey()
  final TrackingMode walkMode;
  @override
  @JsonKey()
  final TrackingMode runMode;

  @override
  String toString() {
    return 'WorkoutModel(id: $id, userId: $userId, squatCount: $squatCount, lungeCount: $lungeCount, walkSteps: $walkSteps, runDistance: $runDistance, duration: $duration, notes: $notes, date: $date, createdAt: $createdAt, updatedAt: $updatedAt, squatMode: $squatMode, lungeMode: $lungeMode, walkMode: $walkMode, runMode: $runMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.squatCount, squatCount) ||
                other.squatCount == squatCount) &&
            (identical(other.lungeCount, lungeCount) ||
                other.lungeCount == lungeCount) &&
            (identical(other.walkSteps, walkSteps) ||
                other.walkSteps == walkSteps) &&
            (identical(other.runDistance, runDistance) ||
                other.runDistance == runDistance) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.squatMode, squatMode) ||
                other.squatMode == squatMode) &&
            (identical(other.lungeMode, lungeMode) ||
                other.lungeMode == lungeMode) &&
            (identical(other.walkMode, walkMode) ||
                other.walkMode == walkMode) &&
            (identical(other.runMode, runMode) || other.runMode == runMode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      squatCount,
      lungeCount,
      walkSteps,
      runDistance,
      duration,
      notes,
      date,
      createdAt,
      updatedAt,
      squatMode,
      lungeMode,
      walkMode,
      runMode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutModelImplCopyWith<_$WorkoutModelImpl> get copyWith =>
      __$$WorkoutModelImplCopyWithImpl<_$WorkoutModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutModelImplToJson(
      this,
    );
  }
}

abstract class _WorkoutModel implements WorkoutModel {
  const factory _WorkoutModel(
      {final String id,
      final String userId,
      final int squatCount,
      final int lungeCount,
      final int walkSteps,
      final double runDistance,
      final int duration,
      final String? notes,
      @DateTimeConverter() required final DateTime date,
      @NullableDateTimeConverter() final DateTime? createdAt,
      @NullableDateTimeConverter() final DateTime? updatedAt,
      final TrackingMode squatMode,
      final TrackingMode lungeMode,
      final TrackingMode walkMode,
      final TrackingMode runMode}) = _$WorkoutModelImpl;

  factory _WorkoutModel.fromJson(Map<String, dynamic> json) =
      _$WorkoutModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  int get squatCount;
  @override
  int get lungeCount;
  @override
  int get walkSteps;
  @override
  double get runDistance;
  @override // km
  int get duration;
  @override // seconds
  String? get notes;
  @override
  @DateTimeConverter()
  DateTime get date;
  @override
  @NullableDateTimeConverter()
  DateTime? get createdAt;
  @override
  @NullableDateTimeConverter()
  DateTime? get updatedAt;
  @override // 추적 모드 (각 운동별) - 기본값 automatic
  TrackingMode get squatMode;
  @override
  TrackingMode get lungeMode;
  @override
  TrackingMode get walkMode;
  @override
  TrackingMode get runMode;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutModelImplCopyWith<_$WorkoutModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
