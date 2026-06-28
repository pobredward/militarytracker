import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

@freezed
class PostModel with _$PostModel {
  const factory PostModel({
    @Default('') String id,
    @Default('') String authorId,
    @Default('') String authorName,
    String? authorPhotoUrl,
    @Default('') String title,
    @Default('') String content,
    @Default([]) List<String> imageUrls, // 이미지 URL 목록
    @Default([]) List<String> videoUrls, // 동영상 URL 목록
    @Default(0) int likes,
    @Default([]) List<String> likedBy, // 좋아요 누른 사용자 ID 목록
    @Default(0) int comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);
}

