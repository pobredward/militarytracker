// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FollowModelImpl _$$FollowModelImplFromJson(Map<String, dynamic> json) =>
    _$FollowModelImpl(
      id: json['id'] as String,
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Timestamp),
    );

Map<String, dynamic> _$$FollowModelImplToJson(_$FollowModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'followerId': instance.followerId,
      'followingId': instance.followingId,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
