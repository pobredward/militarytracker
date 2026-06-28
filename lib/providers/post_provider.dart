import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/post_repository.dart';
import '../models/post_model.dart';

// PostRepository Provider
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

// 게시글 목록 Provider
final postsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final postRepository = ref.watch(postRepositoryProvider);
  return await postRepository.getPosts();
});

// 게시글 새로고침 Provider
final postsRefreshProvider = StateProvider<int>((ref) => 0);





