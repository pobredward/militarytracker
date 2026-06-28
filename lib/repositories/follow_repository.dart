import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow_model.dart';
import '../models/user_profile_model.dart';
import '../models/workout_model.dart';
import '../core/utils/firestore_type_converter.dart';

class FollowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 팔로우하기
  Future<void> followUser(String followerId, String followingId) async {
    if (followerId == followingId) {
      throw Exception('자기 자신을 팔로우할 수 없습니다.');
    }

    final followDoc = _firestore
        .collection('follows')
        .doc('${followerId}_$followingId');

    await followDoc.set({
      'id': '${followerId}_$followingId',
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 팔로워/팔로잉 수 업데이트
    await _updateFollowCounts(followerId, followingId);
  }

  // 언팔로우하기
  Future<void> unfollowUser(String followerId, String followingId) async {
    final followDoc = _firestore
        .collection('follows')
        .doc('${followerId}_$followingId');

    await followDoc.delete();

    // 팔로워/팔로잉 수 업데이트
    await _updateFollowCounts(followerId, followingId);
  }

  // 팔로우 상태 확인
  Future<bool> isFollowing(String followerId, String followingId) async {
    final followDoc = await _firestore
        .collection('follows')
        .doc('${followerId}_$followingId')
        .get();

    return followDoc.exists;
  }

  // 팔로워 목록 가져오기
  Stream<List<String>> getFollowers(String userId) {
    return _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['followerId'] as String).toList());
  }

  // 팔로잉 목록 가져오기
  Stream<List<String>> getFollowing(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['followingId'] as String).toList());
  }

  // 팔로워 수 가져오기
  Future<int> getFollowerCount(String userId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }

  // 팔로잉 수 가져오기
  Future<int> getFollowingCount(String userId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }

  // 사용자 프로필 정보 가져오기
  Future<UserProfileModel> getUserProfile(String userId, String currentUserId) async {
    // 사용자 기본 정보 가져오기
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('사용자를 찾을 수 없습니다.');
    }

    final userData = userDoc.data()!;

    // 팔로우 정보 가져오기
    final followerCount = await getFollowerCount(userId);
    final followingCount = await getFollowingCount(userId);
    final isFollowing = await this.isFollowing(currentUserId, userId);

    // 운동 통계 가져오기
    final workoutSnapshot = await _firestore
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .get();

    int totalSquats = 0;
    int totalLunges = 0;
    int totalWalkSteps = 0;
    double totalRunDistance = 0.0;
    final workoutDates = <String>{};

    for (final doc in workoutSnapshot.docs) {
      final data = doc.data();
      final workout = WorkoutModel.fromJson({
        ...data,
        'id': doc.id,
        'date': FirestoreTypeConverter.dateToMillis(data['date'], fieldName: 'date'),
        'createdAt': FirestoreTypeConverter.dateToMillis(data['createdAt'], fieldName: 'createdAt'),
        'updatedAt': FirestoreTypeConverter.dateToMillis(data['updatedAt'], fieldName: 'updatedAt'),
      });
      totalSquats += workout.squatCount;
      totalLunges += workout.lungeCount;
      totalWalkSteps += workout.walkSteps;
      totalRunDistance += workout.runDistance;

      // 운동한 날짜 수집 (YYYY-MM-DD 형식)
      final dateKey =
          '${workout.date.year}-${workout.date.month.toString().padLeft(2, '0')}-${workout.date.day.toString().padLeft(2, '0')}';
      workoutDates.add(dateKey);
    }

    final totalWorkoutDays = workoutDates.length;

    // 연속 운동 일수 계산
    final streak = await _calculateStreak(userId);

    return UserProfileModel(
      userId: userId,
      displayName: userData['displayName'] as String? ?? '익명',
      photoURL: userData['photoURL'] as String?,
      bio: userData['bio'] as String?,
      totalSquats: totalSquats,
      totalLunges: totalLunges,
      totalWalkSteps: totalWalkSteps,
      totalRunDistance: totalRunDistance,
      totalWorkoutDays: totalWorkoutDays,
      followerCount: followerCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
      streak: streak,
    );
  }

  // 연속 운동 일수 계산
  Future<int> _calculateStreak(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final workoutSnapshot = await _firestore
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    if (workoutSnapshot.docs.isEmpty) return 0;

    final workoutDates = workoutSnapshot.docs.map((doc) {
      final data = doc.data();
      final workout = WorkoutModel.fromJson({
        ...data,
        'id': doc.id,
        'date': FirestoreTypeConverter.dateToMillis(data['date'], fieldName: 'date'),
        'createdAt': FirestoreTypeConverter.dateToMillis(data['createdAt'], fieldName: 'createdAt'),
        'updatedAt': FirestoreTypeConverter.dateToMillis(data['updatedAt'], fieldName: 'updatedAt'),
      });
      return DateTime(workout.date.year, workout.date.month, workout.date.day);
    }).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = today;

    // 오늘 또는 어제에 운동이 없으면 streak는 0
    if (!workoutDates.contains(today) &&
        !workoutDates.contains(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    for (final workoutDate in workoutDates) {
      if (workoutDate == checkDate ||
          workoutDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = workoutDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // 팔로워/팔로잉 수 업데이트 (내부 메서드)
  Future<void> _updateFollowCounts(String followerId, String followingId) async {
    // 팔로워 수 업데이트
    final followerCount = await getFollowerCount(followingId);
    await _firestore.collection('users').doc(followingId).update({
      'followerCount': followerCount,
    });

    // 팔로잉 수 업데이트
    final followingCount = await getFollowingCount(followerId);
    await _firestore.collection('users').doc(followerId).update({
      'followingCount': followingCount,
    });
  }

  // 사용자의 최근 게시글 가져오기
  Stream<List<Map<String, dynamic>>> getUserPosts(String userId, {int limit = 10}) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)  // userId -> authorId로 변경
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }
}
