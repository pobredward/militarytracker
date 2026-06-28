// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FollowModel _$FollowModelFromJson(Map<String, dynamic> json) {
  return _FollowModel.fromJson(json);
}

/// @nodoc
mixin _$FollowModel {
  String get id =>
      throw _privateConstructorUsedError; // 문서 ID (followerId_followingId)
  String get followerId => throw _privateConstructorUsedError; // 팔로우하는 사용자 ID
  String get followingId =>
      throw _privateConstructorUsedError; // 팔로우 당하는 사용자 ID
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FollowModelCopyWith<FollowModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FollowModelCopyWith<$Res> {
  factory $FollowModelCopyWith(
          FollowModel value, $Res Function(FollowModel) then) =
      _$FollowModelCopyWithImpl<$Res, FollowModel>;
  @useResult
  $Res call(
      {String id,
      String followerId,
      String followingId,
      @TimestampConverter() DateTime createdAt});
}

/// @nodoc
class _$FollowModelCopyWithImpl<$Res, $Val extends FollowModel>
    implements $FollowModelCopyWith<$Res> {
  _$FollowModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? followerId = null,
    Object? followingId = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      followerId: null == followerId
          ? _value.followerId
          : followerId // ignore: cast_nullable_to_non_nullable
              as String,
      followingId: null == followingId
          ? _value.followingId
          : followingId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FollowModelImplCopyWith<$Res>
    implements $FollowModelCopyWith<$Res> {
  factory _$$FollowModelImplCopyWith(
          _$FollowModelImpl value, $Res Function(_$FollowModelImpl) then) =
      __$$FollowModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String followerId,
      String followingId,
      @TimestampConverter() DateTime createdAt});
}

/// @nodoc
class __$$FollowModelImplCopyWithImpl<$Res>
    extends _$FollowModelCopyWithImpl<$Res, _$FollowModelImpl>
    implements _$$FollowModelImplCopyWith<$Res> {
  __$$FollowModelImplCopyWithImpl(
      _$FollowModelImpl _value, $Res Function(_$FollowModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? followerId = null,
    Object? followingId = null,
    Object? createdAt = null,
  }) {
    return _then(_$FollowModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      followerId: null == followerId
          ? _value.followerId
          : followerId // ignore: cast_nullable_to_non_nullable
              as String,
      followingId: null == followingId
          ? _value.followingId
          : followingId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FollowModelImpl implements _FollowModel {
  const _$FollowModelImpl(
      {required this.id,
      required this.followerId,
      required this.followingId,
      @TimestampConverter() required this.createdAt});

  factory _$FollowModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FollowModelImplFromJson(json);

  @override
  final String id;
// 문서 ID (followerId_followingId)
  @override
  final String followerId;
// 팔로우하는 사용자 ID
  @override
  final String followingId;
// 팔로우 당하는 사용자 ID
  @override
  @TimestampConverter()
  final DateTime createdAt;

  @override
  String toString() {
    return 'FollowModel(id: $id, followerId: $followerId, followingId: $followingId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FollowModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.followerId, followerId) ||
                other.followerId == followerId) &&
            (identical(other.followingId, followingId) ||
                other.followingId == followingId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, followerId, followingId, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FollowModelImplCopyWith<_$FollowModelImpl> get copyWith =>
      __$$FollowModelImplCopyWithImpl<_$FollowModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FollowModelImplToJson(
      this,
    );
  }
}

abstract class _FollowModel implements FollowModel {
  const factory _FollowModel(
          {required final String id,
          required final String followerId,
          required final String followingId,
          @TimestampConverter() required final DateTime createdAt}) =
      _$FollowModelImpl;

  factory _FollowModel.fromJson(Map<String, dynamic> json) =
      _$FollowModelImpl.fromJson;

  @override
  String get id;
  @override // 문서 ID (followerId_followingId)
  String get followerId;
  @override // 팔로우하는 사용자 ID
  String get followingId;
  @override // 팔로우 당하는 사용자 ID
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$FollowModelImplCopyWith<_$FollowModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
