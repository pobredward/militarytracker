import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../core/config/logger.dart';

class CommentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'comments';

  // 특정 게시글의 댓글 목록 가져오기
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('postId', isEqualTo: postId)
          .get();

      final comments = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CommentModel.fromJson({
          ...data,
          'id': doc.id,
          'createdAt': _parseTimestamp(data['createdAt'])?.toIso8601String(),
          'updatedAt': _parseTimestamp(data['updatedAt'])?.toIso8601String(),
        });
      }).toList();
      
      // 클라이언트에서 정렬 (createdAt 기준 오름차순)
      comments.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return a.createdAt!.compareTo(b.createdAt!);
      });
      
      return comments;
    } catch (e) {
      logger.e('Error getting comments: $e');
      return [];
    }
  }

  // Timestamp 또는 String을 DateTime으로 변환하는 헬퍼 메서드
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        logger.e('Error parsing timestamp string: $e');
        return null;
      }
    }
    
    return null;
  }

  // 댓글 스트림
  Stream<List<CommentModel>> commentsStream(String postId) {
    return _firestore
        .collection(_collection)
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return CommentModel.fromJson({
          ...data,
          'id': doc.id,
          'createdAt': _parseTimestamp(data['createdAt'])?.toIso8601String(),
          'updatedAt': _parseTimestamp(data['updatedAt'])?.toIso8601String(),
        });
      }).toList();
      
      // 클라이언트에서 정렬 (createdAt 기준 오름차순)
      comments.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return a.createdAt!.compareTo(b.createdAt!);
      });
      
      return comments;
    });
  }

  // 댓글 생성
  Future<String?> createComment(CommentModel comment) async {
    try {
      final data = comment.toJson()
        ..remove('id')
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(_collection).add(data);
      
      // 게시글의 댓글 수 증가
      await _firestore.collection('posts').doc(comment.postId).update({
        'comments': FieldValue.increment(1),
      });

      logger.i('Comment created successfully');
      return docRef.id;
    } catch (e) {
      logger.e('Error creating comment: $e');
      return null;
    }
  }

  // 댓글 수정
  Future<bool> updateComment(CommentModel comment) async {
    try {
      final data = comment.toJson()
        ..remove('id')
        ..remove('createdAt')
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(comment.id).update(data);
      logger.i('Comment updated successfully');
      return true;
    } catch (e) {
      logger.e('Error updating comment: $e');
      return false;
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection(_collection).doc(commentId).delete();
      
      // 게시글의 댓글 수 감소
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });

      logger.i('Comment deleted successfully');
      return true;
    } catch (e) {
      logger.e('Error deleting comment: $e');
      return false;
    }
  }

  // 댓글 좋아요 토글
  Future<bool> toggleCommentLike(String commentId, String userId, bool isLiked) async {
    try {
      if (isLiked) {
        // 좋아요 취소
        await _firestore.collection(_collection).doc(commentId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // 좋아요
        await _firestore.collection(_collection).doc(commentId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
      return true;
    } catch (e) {
      logger.e('Error toggling comment like: $e');
      return false;
    }
  }
}

