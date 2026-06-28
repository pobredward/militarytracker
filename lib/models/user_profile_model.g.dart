// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileModelImpl _$$UserProfileModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserProfileModelImpl(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      bio: json['bio'] as String?,
      totalSquats: (json['totalSquats'] as num).toInt(),
      totalLunges: (json['totalLunges'] as num).toInt(),
      totalWalkSteps: (json['totalWalkSteps'] as num).toInt(),
      totalRunDistance: (json['totalRunDistance'] as num).toDouble(),
      totalWorkoutDays: (json['totalWorkoutDays'] as num).toInt(),
      followerCount: (json['followerCount'] as num).toInt(),
      followingCount: (json['followingCount'] as num).toInt(),
      isFollowing: json['isFollowing'] as bool,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$UserProfileModelImplToJson(
        _$UserProfileModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'bio': instance.bio,
      'totalSquats': instance.totalSquats,
      'totalLunges': instance.totalLunges,
      'totalWalkSteps': instance.totalWalkSteps,
      'totalRunDistance': instance.totalRunDistance,
      'totalWorkoutDays': instance.totalWorkoutDays,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
      'isFollowing': instance.isFollowing,
      'streak': instance.streak,
    };
