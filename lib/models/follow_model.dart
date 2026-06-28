import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_model.freezed.dart';
part 'follow_model.g.dart';

/// 팔로우 관계를 나타내는 모델
@freezed
class FollowModel with _$FollowModel {
  const factory FollowModel({
    required String id, // 문서 ID (followerId_followingId)
    required String followerId, // 팔로우하는 사용자 ID
    required String followingId, // 팔로우 당하는 사용자 ID
    @TimestampConverter() required DateTime createdAt, // 팔로우 시작 시간
  }) = _FollowModel;

  factory FollowModel.fromJson(Map<String, dynamic> json) =>
      _$FollowModelFromJson(json);
}

/// Timestamp 변환을 위한 컨버터
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
  }

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
