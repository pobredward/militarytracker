import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') String id,
    @Default('') String email,
    @Default('게스트') String displayName,
    String? photoUrl,
    String? bio, // 자기소개
    @Default('email') String authProvider, // 'email', 'google'
    @Default(0) int totalSquats,
    @Default(0) int totalLunges,
    @Default(0) int totalWalkSteps,
    @Default(0.0) double totalRunDistance,
    @Default(0) int workoutDays,
    @Default(0) int followerCount, // 팔로워 수
    @Default(0) int followingCount, // 팔로잉 수
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

