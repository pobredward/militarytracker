import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/comment_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/user_card.dart';
import '../../profile/presentation/user_profile_screen.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  CommentModel? _editingComment;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startEditComment(CommentModel comment) {
    setState(() {
      _editingComment = comment;
      _commentController.text = comment.content;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelEditComment() {
    setState(() {
      _editingComment = null;
      _commentController.clear();
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);

    final authState = ref.read(authStateProvider);
    final currentUser = ref.read(currentUserProvider);

    await authState.when(
      data: (firebaseUser) async {
        if (firebaseUser == null) return;

        await currentUser.when(
          data: (user) async {
            if (user == null) return;

            if (_editingComment != null) {
              // 댓글 수정
              final updatedComment = _editingComment!.copyWith(
                content: _commentController.text.trim(),
                updatedAt: DateTime.now(),
              );

              final success = await ref.read(commentRepositoryProvider).updateComment(updatedComment);

              if (success && mounted) {
                _commentController.clear();
                setState(() => _editingComment = null);
                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('댓글이 수정되었습니다')),
                );
              }
            } else {
              // 새 댓글 작성
              final newComment = CommentModel(
                postId: widget.post.id,
                authorId: firebaseUser.uid,
                authorName: user.displayName,
                authorPhotoUrl: user.photoUrl,
                content: _commentController.text.trim(),
              );

              final commentId = await ref.read(commentRepositoryProvider).createComment(newComment);

              if (commentId != null && mounted) {
                _commentController.clear();
                FocusScope.of(context).unfocus();
              }
            }
          },
          loading: () {},
          error: (_, __) {},
        );
      },
      loading: () {},
      error: (_, __) {},
    );

    if (mounted) {
      setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _toggleLike() async {
    final authState = ref.read(authStateProvider);
    
    await authState.when(
      data: (firebaseUser) async {
        if (firebaseUser == null) return;

        final isLiked = widget.post.likedBy.contains(firebaseUser.uid);
        await ref.read(postRepositoryProvider).toggleLike(
          widget.post.id,
          firebaseUser.uid,
          isLiked,
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '게시글 삭제',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '정말로 이 게시글을 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref.read(postRepositoryProvider).deletePost(widget.post.id);

    if (mounted) {
      if (success) {
        ref.invalidate(postsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 삭제되었습니다'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMoreOptions() {
    final authState = ref.read(authStateProvider);
    
    authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) return;
        
        final isAuthor = widget.post.authorId == firebaseUser.uid;

        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E1E1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAuthor) ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF00C853)),
                    title: const Text(
                      '수정',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(post: widget.post),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _deletePost();
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.orange),
                    title: const Text(
                      '신고',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('신고 기능은 추후 구현 예정입니다')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final commentsAsync = ref.watch(commentsProvider(widget.post.id));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '게시글',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0E0E0),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF9E9E9E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF9E9E9E)),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 게시글 내용
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // 작성자 정보
                GestureDetector(
                  onTap: () {
                    // 작성자 프로필 페이지로 직접 이동
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(userId: widget.post.authorId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Hero(
                        tag: 'user_avatar_${widget.post.authorId}',
                        child: widget.post.authorPhotoUrl != null
                            ? CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(widget.post.authorPhotoUrl!),
                                backgroundColor: const Color(0xFF2A2A2A),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.post.authorName.isNotEmpty 
                                        ? widget.post.authorName[0].toUpperCase() 
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00C853),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.authorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.post.createdAt != null
                                  ? DateFormatter.toRelativeTime(widget.post.createdAt!)
                                  : '방금 전',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF616161),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 제목
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E0E0),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // 내용
                Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9E9E9E),
                    height: 1.6,
                  ),
                ),
                
                // 이미지 갤러리
                if (widget.post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildImageGallery(),
                  if (widget.post.imageUrls.length > 1) ...[
                    const SizedBox(height: 12),
                    _buildPageIndicator(),
                  ],
                ],
                
                const SizedBox(height: 24),

                // 좋아요 & 댓글 수
                Row(
                  children: [
                    authState.when(
                      data: (firebaseUser) {
                        final isLiked = firebaseUser != null && 
                            widget.post.likedBy.contains(firebaseUser.uid);
                        
                        return InkWell(
                          onTap: _toggleLike,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isLiked 
                                  ? const Color(0xFF00C853).withOpacity(0.1)
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: isLiked ? const Color(0xFF00C853) : const Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.post.likes}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isLiked ? const Color(0xFF00C853) : const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_border, size: 18, color: Color(0xFF9E9E9E)),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.post.likes}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.post.comments}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 댓글 섹션
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 20),
                
                Text(
                  '댓글 ${widget.post.comments}개',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 16),

                // 댓글 목록
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            '첫 번째 댓글을 작성해보세요!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: comments.map((comment) => _buildCommentItem(comment)).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      '댓글을 불러올 수 없습니다',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 댓글 입력
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A)),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 수정 중 표시
                  if (_editingComment != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF00C853),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '댓글 수정 중...',
                              style: TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _cancelEditComment,
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Color(0xFFE0E0E0)),
                          decoration: InputDecoration(
                            hintText: _editingComment != null 
                                ? '댓글을 수정하세요...'
                                : '댓글을 입력하세요...',
                            hintStyle: const TextStyle(color: Color(0xFF616161)),
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          enabled: !_isSubmittingComment,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00E676)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isSubmittingComment ? null : _submitComment,
                          icon: _isSubmittingComment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Icon(
                                  _editingComment != null ? Icons.check : Icons.send,
                                  color: Colors.black,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final authState = ref.watch(authStateProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // 댓글 작성자 프로필 페이지로 직접 이동
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: comment.authorId),
                    ),
                  );
                },
                child: Hero(
                  tag: 'user_avatar_${comment.authorId}',
                  child: comment.authorPhotoUrl != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(comment.authorPhotoUrl!),
                          backgroundColor: const Color(0xFF2A2A2A),
                        )
                      : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              comment.authorName.isNotEmpty 
                                  ? comment.authorName[0].toUpperCase() 
                                  : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00C853),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // 댓글 작성자 프로필 카드 표시
                    UserDetailCard.show(context, comment.authorId);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      Text(
                        comment.createdAt != null
                            ? DateFormatter.toRelativeTime(comment.createdAt!)
                            : '방금 전',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              authState.when(
                data: (firebaseUser) {
                  if (firebaseUser != null && comment.authorId == firebaseUser.uid) {
                    return PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF616161)),
                      color: const Color(0xFF2A2A2A),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Color(0xFF00C853)),
                              SizedBox(width: 8),
                              Text('수정', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _startEditComment(comment);
                        } else if (value == 'delete') {
                          final success = await ref.read(commentRepositoryProvider).deleteComment(
                            comment.id,
                            comment.postId,
                          );
                          
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('댓글이 삭제되었습니다')),
                            );
                          }
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 개선된 이미지 갤러리 위젯
  /// - 세로/가로 사진 자동 감지
  /// - 다양한 비율 처리
  /// - contain으로 원본 비율 유지
  Widget _buildImageGallery() {
    return AspectRatio(
      aspectRatio: 1.0, // 정사각형 컨테이너
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.post.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreenImage(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1A1A1A),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.post.imageUrls[index],
                  fit: BoxFit.contain, // 원본 비율 유지
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF00C853),
                        strokeWidth: 3,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF616161),
                            size: 64,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              color: Color(0xFF616161),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 페이지 인디케이터
  Widget _buildPageIndicator() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.post.imageUrls.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentImageIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentImageIndex == index
                  ? const Color(0xFF00C853)
                  : const Color(0xFF00C853).withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  /// 전체 화면 이미지 뷰어
  void _showFullScreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrls: widget.post.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// 전체 화면 이미지 뷰어 위젯
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 이미지 뷰어
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF00C853),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // 상단 앱바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 48), // 균형을 위한 공간
                  ],
                ),
              ),
            ),
          ),
          
          // 하단 인디케이터
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imageUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

