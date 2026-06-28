// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '게스트',
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      authProvider: json['authProvider'] as String? ?? 'email',
      totalSquats: (json['totalSquats'] as num?)?.toInt() ?? 0,
      totalLunges: (json['totalLunges'] as num?)?.toInt() ?? 0,
      totalWalkSteps: (json['totalWalkSteps'] as num?)?.toInt() ?? 0,
      totalRunDistance: (json['totalRunDistance'] as num?)?.toDouble() ?? 0.0,
      workoutDays: (json['workoutDays'] as num?)?.toInt() ?? 0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'bio': instance.bio,
      'authProvider': instance.authProvider,
      'totalSquats': instance.totalSquats,
      'totalLunges': instance.totalLunges,
      'totalWalkSteps': instance.totalWalkSteps,
      'totalRunDistance': instance.totalRunDistance,
      'workoutDays': instance.workoutDays,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
    };
