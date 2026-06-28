import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// 사용자 프로필 정보를 나타내는 모델 (다른 사용자의 정보를 볼 때 사용)
@freezed
class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String userId,
    required String displayName,
    required String? photoURL,
    required String? bio, // 자기소개
    required int totalSquats,
    required int totalLunges,
    required int totalWalkSteps,
    required double totalRunDistance,
    required int totalWorkoutDays,
    required int followerCount, // 팔로워 수
    required int followingCount, // 팔로잉 수
    required bool isFollowing, // 현재 사용자가 이 프로필을 팔로우 중인지
    @Default(0) int streak, // 연속 운동 일수
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}
