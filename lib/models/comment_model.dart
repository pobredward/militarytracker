import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    @Default('') String id,
    @Default('') String postId,
    @Default('') String authorId,
    @Default('') String authorName,
    String? authorPhotoUrl,
    @Default('') String content,
    @Default(0) int likes,
    @Default([]) List<String> likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}




