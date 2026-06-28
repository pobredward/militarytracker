// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) {
  return _UserProfileModel.fromJson(json);
}

/// @nodoc
mixin _$UserProfileModel {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoURL => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError; // 자기소개
  int get totalSquats => throw _privateConstructorUsedError;
  int get totalLunges => throw _privateConstructorUsedError;
  int get totalWalkSteps => throw _privateConstructorUsedError;
  double get totalRunDistance => throw _privateConstructorUsedError;
  int get totalWorkoutDays => throw _privateConstructorUsedError;
  int get followerCount => throw _privateConstructorUsedError; // 팔로워 수
  int get followingCount => throw _privateConstructorUsedError; // 팔로잉 수
  bool get isFollowing =>
      throw _privateConstructorUsedError; // 현재 사용자가 이 프로필을 팔로우 중인지
  int get streak => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserProfileModelCopyWith<UserProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileModelCopyWith<$Res> {
  factory $UserProfileModelCopyWith(
          UserProfileModel value, $Res Function(UserProfileModel) then) =
      _$UserProfileModelCopyWithImpl<$Res, UserProfileModel>;
  @useResult
  $Res call(
      {String userId,
      String displayName,
      String? photoURL,
      String? bio,
      int totalSquats,
      int totalLunges,
      int totalWalkSteps,
      double totalRunDistance,
      int totalWorkoutDays,
      int followerCount,
      int followingCount,
      bool isFollowing,
      int streak});
}

/// @nodoc
class _$UserProfileModelCopyWithImpl<$Res, $Val extends UserProfileModel>
    implements $UserProfileModelCopyWith<$Res> {
  _$UserProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? bio = freezed,
    Object? totalSquats = null,
    Object? totalLunges = null,
    Object? totalWalkSteps = null,
    Object? totalRunDistance = null,
    Object? totalWorkoutDays = null,
    Object? followerCount = null,
    Object? followingCount = null,
    Object? isFollowing = null,
    Object? streak = null,
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
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
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
      totalWorkoutDays: null == totalWorkoutDays
          ? _value.totalWorkoutDays
          : totalWorkoutDays // ignore: cast_nullable_to_non_nullable
              as int,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      followingCount: null == followingCount
          ? _value.followingCount
          : followingCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFollowing: null == isFollowing
          ? _value.isFollowing
          : isFollowing // ignore: cast_nullable_to_non_nullable
              as bool,
      streak: null == streak
          ? _value.streak
          : streak // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileModelImplCopyWith<$Res>
    implements $UserProfileModelCopyWith<$Res> {
  factory _$$UserProfileModelImplCopyWith(_$UserProfileModelImpl value,
          $Res Function(_$UserProfileModelImpl) then) =
      __$$UserProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String displayName,
      String? photoURL,
      String? bio,
      int totalSquats,
      int totalLunges,
      int totalWalkSteps,
      double totalRunDistance,
      int totalWorkoutDays,
      int followerCount,
      int followingCount,
      bool isFollowing,
      int streak});
}

/// @nodoc
class __$$UserProfileModelImplCopyWithImpl<$Res>
    extends _$UserProfileModelCopyWithImpl<$Res, _$UserProfileModelImpl>
    implements _$$UserProfileModelImplCopyWith<$Res> {
  __$$UserProfileModelImplCopyWithImpl(_$UserProfileModelImpl _value,
      $Res Function(_$UserProfileModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? bio = freezed,
    Object? totalSquats = null,
    Object? totalLunges = null,
    Object? totalWalkSteps = null,
    Object? totalRunDistance = null,
    Object? totalWorkoutDays = null,
    Object? followerCount = null,
    Object? followingCount = null,
    Object? isFollowing = null,
    Object? streak = null,
  }) {
    return _then(_$UserProfileModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
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
      totalWorkoutDays: null == totalWorkoutDays
          ? _value.totalWorkoutDays
          : totalWorkoutDays // ignore: cast_nullable_to_non_nullable
              as int,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      followingCount: null == followingCount
          ? _value.followingCount
          : followingCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFollowing: null == isFollowing
          ? _value.isFollowing
          : isFollowing // ignore: cast_nullable_to_non_nullable
              as bool,
      streak: null == streak
          ? _value.streak
          : streak // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileModelImpl implements _UserProfileModel {
  const _$UserProfileModelImpl(
      {required this.userId,
      required this.displayName,
      required this.photoURL,
      required this.bio,
      required this.totalSquats,
      required this.totalLunges,
      required this.totalWalkSteps,
      required this.totalRunDistance,
      required this.totalWorkoutDays,
      required this.followerCount,
      required this.followingCount,
      required this.isFollowing,
      this.streak = 0});

  factory _$UserProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String? photoURL;
  @override
  final String? bio;
// 자기소개
  @override
  final int totalSquats;
  @override
  final int totalLunges;
  @override
  final int totalWalkSteps;
  @override
  final double totalRunDistance;
  @override
  final int totalWorkoutDays;
  @override
  final int followerCount;
// 팔로워 수
  @override
  final int followingCount;
// 팔로잉 수
  @override
  final bool isFollowing;
// 현재 사용자가 이 프로필을 팔로우 중인지
  @override
  @JsonKey()
  final int streak;

  @override
  String toString() {
    return 'UserProfileModel(userId: $userId, displayName: $displayName, photoURL: $photoURL, bio: $bio, totalSquats: $totalSquats, totalLunges: $totalLunges, totalWalkSteps: $totalWalkSteps, totalRunDistance: $totalRunDistance, totalWorkoutDays: $totalWorkoutDays, followerCount: $followerCount, followingCount: $followingCount, isFollowing: $isFollowing, streak: $streak)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.totalSquats, totalSquats) ||
                other.totalSquats == totalSquats) &&
            (identical(other.totalLunges, totalLunges) ||
                other.totalLunges == totalLunges) &&
            (identical(other.totalWalkSteps, totalWalkSteps) ||
                other.totalWalkSteps == totalWalkSteps) &&
            (identical(other.totalRunDistance, totalRunDistance) ||
                other.totalRunDistance == totalRunDistance) &&
            (identical(other.totalWorkoutDays, totalWorkoutDays) ||
                other.totalWorkoutDays == totalWorkoutDays) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.followingCount, followingCount) ||
                other.followingCount == followingCount) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.streak, streak) || other.streak == streak));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      displayName,
      photoURL,
      bio,
      totalSquats,
      totalLunges,
      totalWalkSteps,
      totalRunDistance,
      totalWorkoutDays,
      followerCount,
      followingCount,
      isFollowing,
      streak);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileModelImplCopyWith<_$UserProfileModelImpl> get copyWith =>
      __$$UserProfileModelImplCopyWithImpl<_$UserProfileModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileModelImplToJson(
      this,
    );
  }
}

abstract class _UserProfileModel implements UserProfileModel {
  const factory _UserProfileModel(
      {required final String userId,
      required final String displayName,
      required final String? photoURL,
      required final String? bio,
      required final int totalSquats,
      required final int totalLunges,
      required final int totalWalkSteps,
      required final double totalRunDistance,
      required final int totalWorkoutDays,
      required final int followerCount,
      required final int followingCount,
      required final bool isFollowing,
      final int streak}) = _$UserProfileModelImpl;

  factory _UserProfileModel.fromJson(Map<String, dynamic> json) =
      _$UserProfileModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  String? get photoURL;
  @override
  String? get bio;
  @override // 자기소개
  int get totalSquats;
  @override
  int get totalLunges;
  @override
  int get totalWalkSteps;
  @override
  double get totalRunDistance;
  @override
  int get totalWorkoutDays;
  @override
  int get followerCount;
  @override // 팔로워 수
  int get followingCount;
  @override // 팔로잉 수
  bool get isFollowing;
  @override // 현재 사용자가 이 프로필을 팔로우 중인지
  int get streak;
  @override
  @JsonKey(ignore: true)
  _$$UserProfileModelImplCopyWith<_$UserProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
