// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError; // 자기소개
  String get authProvider =>
      throw _privateConstructorUsedError; // 'email', 'google'
  int get totalSquats => throw _privateConstructorUsedError;
  int get totalLunges => throw _privateConstructorUsedError;
  int get totalWalkSteps => throw _privateConstructorUsedError;
  double get totalRunDistance => throw _privateConstructorUsedError;
  int get workoutDays => throw _privateConstructorUsedError;
  int get followerCount => throw _privateConstructorUsedError; // 팔로워 수
  int get followingCount => throw _privateConstructorUsedError; // 팔로잉 수
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String id,
      String email,
      String displayName,
      String? photoUrl,
      String? bio,
      String authProvider,
      int totalSquats,
      int totalLunges,
      int totalWalkSteps,
      double totalRunDistance,
      int workoutDays,
      int followerCount,
      int followingCount,
      DateTime? createdAt,
      DateTime? lastLoginAt});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = null,
    Object? photoUrl = freezed,
    Object? bio = freezed,
    Object? authProvider = null,
    Object? totalSquats = null,
    Object? totalLunges = null,
    Object? totalWalkSteps = null,
    Object? totalRunDistance = null,
    Object? workoutDays = null,
    Object? followerCount = null,
    Object? followingCount = null,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      authProvider: null == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String,
      totalSquats: null == totalSquats
          ? _value.totalSquats
          : totalSquats // ignore: cast_nullable_to_non_nullable
              as int,
      totalLunges: null == totalLunges
          ? _value.totalLunges
          : totalLunges // ignore: cast_nullable_to_non_nullable
              as int,
      totalWalkSteps: null == totalWalkSteps
          ? _value.totalWalkSteps
          : totalWalkSteps // ignore: cast_nullable_to_non_nullable
              as int,
      totalRunDistance: null == totalRunDistance
          ? _value.totalRunDistance
          : totalRunDistance // ignore: cast_nullable_to_non_nullable
              as double,
      workoutDays: null == workoutDays
          ? _value.workoutDays
          : workoutDays // ignore: cast_nullable_to_non_nullable
              as int,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      followingCount: null == followingCount
          ? _value.followingCount
          : followingCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastLoginAt: freezed == lastLoginAt
          ? _value.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String displayName,
      String? photoUrl,
      String? bio,
      String authProvider,
      int totalSquats,
      int totalLunges,
      int totalWalkSteps,
      double totalRunDistance,
      int workoutDays,
      int followerCount,
      int followingCount,
      DateTime? createdAt,
      DateTime? lastLoginAt});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = null,
    Object? photoUrl = freezed,
    Object? bio = freezed,
    Object? authProvider = null,
    Object? totalSquats = null,
    Object? totalLunges = null,
    Object? totalWalkSteps = null,
    Object? totalRunDistance = null,
    Object? workoutDays = null,
    Object? followerCount = null,
    Object? followingCount = null,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
  }) {
    return _then(_$UserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      authProvider: null == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String,
      totalSquats: null == totalSquats
          ? _value.totalSquats
          : totalSquats // ignore: cast_nullable_to_non_nullable
              as int,
      totalLunges: null == totalLunges
          ? _value.totalLunges
          : totalLunges // ignore: cast_nullable_to_non_nullable
              as int,
      totalWalkSteps: null == totalWalkSteps
          ? _value.totalWalkSteps
          : totalWalkSteps // ignore: cast_nullable_to_non_nullable
              as int,
      totalRunDistance: null == totalRunDistance
          ? _value.totalRunDistance
          : totalRunDistance // ignore: cast_nullable_to_non_nullable
              as double,
      workoutDays: null == workoutDays
          ? _value.workoutDays
          : workoutDays // ignore: cast_nullable_to_non_nullable
              as int,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      followingCount: null == followingCount
          ? _value.followingCount
          : followingCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastLoginAt: freezed == lastLoginAt
          ? _value.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {this.id = '',
      this.email = '',
      this.displayName = '게스트',
      this.photoUrl,
      this.bio,
      this.authProvider = 'email',
      this.totalSquats = 0,
      this.totalLunges = 0,
      this.totalWalkSteps = 0,
      this.totalRunDistance = 0.0,
      this.workoutDays = 0,
      this.followerCount = 0,
      this.followingCount = 0,
      this.createdAt,
      this.lastLoginAt});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final String displayName;
  @override
  final String? photoUrl;
  @override
  final String? bio;
// 자기소개
  @override
  @JsonKey()
  final String authProvider;
// 'email', 'google'
  @override
  @JsonKey()
  final int totalSquats;
  @override
  @JsonKey()
  final int totalLunges;
  @override
  @JsonKey()
  final int totalWalkSteps;
  @override
  @JsonKey()
  final double totalRunDistance;
  @override
  @JsonKey()
  final int workoutDays;
  @override
  @JsonKey()
  final int followerCount;
// 팔로워 수
  @override
  @JsonKey()
  final int followingCount;
// 팔로잉 수
  @override
  final DateTime? createdAt;
  @override
  final DateTime? lastLoginAt;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, photoUrl: $photoUrl, bio: $bio, authProvider: $authProvider, totalSquats: $totalSquats, totalLunges: $totalLunges, totalWalkSteps: $totalWalkSteps, totalRunDistance: $totalRunDistance, workoutDays: $workoutDays, followerCount: $followerCount, followingCount: $followingCount, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.authProvider, authProvider) ||
                other.authProvider == authProvider) &&
            (identical(other.totalSquats, totalSquats) ||
                other.totalSquats == totalSquats) &&
            (identical(other.totalLunges, totalLunges) ||
                other.totalLunges == totalLunges) &&
            (identical(other.totalWalkSteps, totalWalkSteps) ||
                other.totalWalkSteps == totalWalkSteps) &&
            (identical(other.totalRunDistance, totalRunDistance) ||
                other.totalRunDistance == totalRunDistance) &&
            (identical(other.workoutDays, workoutDays) ||
                other.workoutDays == workoutDays) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.followingCount, followingCount) ||
                other.followingCount == followingCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      displayName,
      photoUrl,
      bio,
      authProvider,
      totalSquats,
      totalLunges,
      totalWalkSteps,
      totalRunDistance,
      workoutDays,
      followerCount,
      followingCount,
      createdAt,
      lastLoginAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {final String id,
      final String email,
      final String displayName,
      final String? photoUrl,
      final String? bio,
      final String authProvider,
      final int totalSquats,
      final int totalLunges,
      final int totalWalkSteps,
      final double totalRunDistance,
      final int workoutDays,
      final int followerCount,
      final int followingCount,
      final DateTime? createdAt,
      final DateTime? lastLoginAt}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String get displayName;
  @override
  String? get photoUrl;
  @override
  String? get bio;
  @override // 자기소개
  String get authProvider;
  @override // 'email', 'google'
  int get totalSquats;
  @override
  int get totalLunges;
  @override
  int get totalWalkSteps;
  @override
  double get totalRunDistance;
  @override
  int get workoutDays;
  @override
  int get followerCount;
  @override // 팔로워 수
  int get followingCount;
  @override // 팔로잉 수
  DateTime? get createdAt;
  @override
  DateTime? get lastLoginAt;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
