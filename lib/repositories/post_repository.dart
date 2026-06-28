import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../core/config/logger.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  // 게시글 목록 가져오기
  Future<List<PostModel>> getPosts({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PostModel.fromJson({
          ...data,
          'id': doc.id,
          'createdAt': _parseTimestamp(data['createdAt'])?.toIso8601String(),
          'updatedAt': _parseTimestamp(data['updatedAt'])?.toIso8601String(),
        });
      }).toList();
    } catch (e) {
      logger.e('Error getting posts: $e');
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

  // 게시글 생성
  Future<String?> createPost(PostModel post) async {
    try {
      logger.i('Creating post with title: "${post.title}"');
      logger.i('Author ID: ${post.authorId}');
      logger.i('Image URLs count: ${post.imageUrls.length}');
      
      final data = post.toJson();
      
      // ID 필드 제거 (Firestore가 자동 생성)
      data.remove('id');
      
      // Timestamp 설정
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      logger.d('Post data to be saved: ${data.keys.toList()}');

      final docRef = await _firestore.collection(_collection).add(data);
      logger.i('Post created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      logger.e('Error creating post: $e');
      logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  // 게시글 수정
  Future<bool> updatePost(PostModel post) async {
    try {
      final data = post.toJson()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(post.id).update(data);
      logger.i('Post updated successfully');
      return true;
    } catch (e) {
      logger.e('Error updating post: $e');
      return false;
    }
  }

  // 게시글 삭제
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
      logger.i('Post deleted successfully');
      return true;
    } catch (e) {
      logger.e('Error deleting post: $e');
      return false;
    }
  }

  // 좋아요 토글
  Future<bool> toggleLike(String postId, String userId, bool isLiked) async {
    try {
      if (isLiked) {
        // 좋아요 취소
        await _firestore.collection(_collection).doc(postId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // 좋아요
        await _firestore.collection(_collection).doc(postId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
      return true;
    } catch (e) {
      logger.e('Error toggling like: $e');
      return false;
    }
  }

  // 특정 게시글 가져오기
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return PostModel.fromJson({
        ...data,
        'id': doc.id,
        'createdAt': _parseTimestamp(data['createdAt'])?.toIso8601String(),
        'updatedAt': _parseTimestamp(data['updatedAt'])?.toIso8601String(),
      });
    } catch (e) {
      logger.e('Error getting post: $e');
      return null;
    }
  }

  // 게시글 스트림
  Stream<PostModel?> postStream(String postId) {
    return _firestore
        .collection(_collection)
        .doc(postId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return PostModel.fromJson({
        ...data,
        'id': doc.id,
        'createdAt': _parseTimestamp(data['createdAt'])?.toIso8601String(),
        'updatedAt': _parseTimestamp(data['updatedAt'])?.toIso8601String(),
      });
    });
  }
}

