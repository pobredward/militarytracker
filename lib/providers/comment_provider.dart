import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/comment_repository.dart';
import '../models/comment_model.dart';

// CommentRepository Provider
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});

// 특정 게시글의 댓글 목록 Provider
final commentsProvider = StreamProvider.autoDispose.family<List<CommentModel>, String>(
  (ref, postId) {
    final commentRepository = ref.watch(commentRepositoryProvider);
    return commentRepository.commentsStream(postId);
  },
);




