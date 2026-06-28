import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';
import '../core/config/logger.dart';
import '../core/config/scoring_config.dart';

/// Workout Repository 에러 유형
enum WorkoutRepositoryError {
  networkError,
  permissionDenied,
  notFound,
  invalidData,
  unknown,
}

/// Workout Repository Exception
class WorkoutRepositoryException implements Exception {
  final WorkoutRepositoryError type;
  final String message;
  final dynamic originalError;

  WorkoutRepositoryException({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'WorkoutRepositoryException($type): $message';
}

class WorkoutRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'workouts';

  /// 생성자 주입을 통한 의존성 주입
  /// 
  /// 테스트 시 Mock 객체를 주입할 수 있도록 선택적 파라미터 제공
  WorkoutRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore 에러를 Repository Exception으로 변환
  WorkoutRepositoryException _handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return WorkoutRepositoryException(
            type: WorkoutRepositoryError.permissionDenied,
            message: '데이터 접근 권한이 없습니다',
            originalError: error,
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return WorkoutRepositoryException(
            type: WorkoutRepositoryError.networkError,
            message: '네트워크 연결을 확인해주세요',
            originalError: error,
          );
        case 'not-found':
          return WorkoutRepositoryException(
            type: WorkoutRepositoryError.notFound,
            message: '운동 기록을 찾을 수 없습니다',
            originalError: error,
          );
        default:
          return WorkoutRepositoryException(
            type: WorkoutRepositoryError.unknown,
            message: '알 수 없는 오류가 발생했습니다',
            originalError: error,
          );
      }
    }
    
    return WorkoutRepositoryException(
      type: WorkoutRepositoryError.unknown,
      message: '알 수 없는 오류가 발생했습니다',
      originalError: error,
    );
  }

  // 오늘의 운동 기록 가져오기 (개선된 에러 처리)
  Future<WorkoutModel?> getTodayWorkout(String userId) async {
    try {
      if (userId.isEmpty) {
        throw WorkoutRepositoryException(
          type: WorkoutRepositoryError.invalidData,
          message: 'User ID가 유효하지 않습니다',
        );
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      
      // 안전한 Timestamp 변환
      return WorkoutModel.fromJson({
        ...data,
        'id': doc.id,
      });
    } on WorkoutRepositoryException {
      rethrow;
    } catch (e) {
      final exception = _handleFirestoreError(e);
      logger.e('Error getting today workout: ${exception.message}', error: e);
      throw exception;
    }
  }

  // 특정 날짜의 운동 기록 가져오기 (개선된 에러 처리)
  Future<WorkoutModel?> getWorkoutByDate(String userId, DateTime date) async {
    try {
      if (userId.isEmpty) {
        throw WorkoutRepositoryException(
          type: WorkoutRepositoryError.invalidData,
          message: 'User ID가 유효하지 않습니다',
        );
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      
      return WorkoutModel.fromJson({
        ...data,
        'id': doc.id,
      });
    } on WorkoutRepositoryException {
      rethrow;
    } catch (e) {
      final exception = _handleFirestoreError(e);
      logger.e('Error getting workout by date: ${exception.message}', error: e);
      throw exception;
    }
  }

  // 운동 기록 생성 + rankings 업데이트 (개선된 에러 처리)
  Future<String?> createWorkout(WorkoutModel workout) async {
    try {
      if (workout.userId.isEmpty) {
        logger.e('User ID가 유효하지 않습니다');
        return null;
      }

      // Firestore batch 사용 (트랜잭션)
      final batch = _firestore.batch();

      // 1. workouts 컬렉션에 저장
      final workoutRef = _firestore.collection(_collection).doc();
      final workoutData = workout.toJson();
      workoutData['createdAt'] = FieldValue.serverTimestamp();
      workoutData['updatedAt'] = FieldValue.serverTimestamp();
      workoutData.remove('id');
      
      batch.set(workoutRef, workoutData);
      logger.i('Preparing to create workout: ${workoutRef.id}');

      // 2. rankings 컬렉션도 업데이트
      await _updateRankingsBatch(batch, workout);

      // 3. 배치 커밋 (한 번에 실행)
      await batch.commit();
      logger.i('✅ Workout and rankings created successfully: ${workoutRef.id}');
      
      return workoutRef.id;
    } catch (e, stackTrace) {
      logger.e('❌ Error creating workout: $e');
      logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  // 운동 기록 업데이트 + rankings 업데이트 (개선된 에러 처리)
  Future<bool> updateWorkout(WorkoutModel workout) async {
    try {
      if (workout.id.isEmpty) {
        logger.e('Workout ID가 유효하지 않습니다');
        return false;
      }
      
      if (workout.userId.isEmpty) {
        logger.e('User ID가 유효하지 않습니다');
        return false;
      }

      // Firestore batch 사용
      final batch = _firestore.batch();

      // 1. workouts 업데이트
      final workoutRef = _firestore.collection(_collection).doc(workout.id);
      final workoutData = workout.toJson();
      workoutData['updatedAt'] = FieldValue.serverTimestamp();
      workoutData.remove('id');
      workoutData.remove('createdAt');
      
      batch.update(workoutRef, workoutData);

      // 2. rankings 업데이트
      await _updateRankingsBatch(batch, workout);

      // 3. 배치 커밋
      await batch.commit();
      logger.i('✅ Workout and rankings updated successfully: ${workout.id}');
      return true;
    } catch (e, stackTrace) {
      logger.e('❌ Error updating workout: $e');
      logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  // 운동 기록 삭제 (개선된 에러 처리)
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      if (workoutId.isEmpty) {
        throw WorkoutRepositoryException(
          type: WorkoutRepositoryError.invalidData,
          message: 'Workout ID가 유효하지 않습니다',
        );
      }

      await _firestore.collection(_collection).doc(workoutId).delete();
      logger.i('Workout deleted successfully: $workoutId');
      return true;
    } on WorkoutRepositoryException {
      rethrow;
    } catch (e) {
      final exception = _handleFirestoreError(e);
      logger.e('Error deleting workout: ${exception.message}', error: e);
      throw exception;
    }
  }

  // 사용자의 운동 기록 목록 가져오기
  Future<List<WorkoutModel>> getWorkoutHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutModel.fromJson({
          ...data,
          'id': doc.id,
          'date': (data['date'] as Timestamp).millisecondsSinceEpoch,
          'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch,
        });
      }).toList();
    } catch (e) {
      logger.e('Error getting workout history: $e');
      return [];
    }
  }

  // 사용자의 운동 기록 스트림
  Stream<List<WorkoutModel>> workoutHistoryStream(
    String userId, {
    int limit = 30,
  }) {
    try {
      logger.i('Starting workout history stream for user: $userId');
      
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .snapshots()
          .handleError((error) {
        logger.e('Workout history stream error: $error');
      }).map((snapshot) {
        logger.i('Received ${snapshot.docs.length} workout documents');
        
        return snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            logger.d('Processing workout doc: ${doc.id}');
            
            return WorkoutModel.fromJson({
              ...data,
              'id': doc.id,
            });
          } catch (e) {
            logger.e('Error parsing workout doc ${doc.id}: $e');
            // 에러가 발생한 문서는 기본값으로 반환
            return WorkoutModel(
              id: doc.id,
              userId: userId,
              date: DateTime.now(),
            );
          }
        }).toList();
      });
    } catch (e) {
      logger.e('Error creating workout history stream: $e');
      // 에러 발생 시 빈 스트림 반환
      return Stream.value([]);
    }
  }

  // 특정 기간의 운동 기록 가져오기
  Future<List<WorkoutModel>> getWorkoutsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutModel.fromJson({
          ...data,
          'id': doc.id,
          'date': (data['date'] as Timestamp).millisecondsSinceEpoch,
          'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch,
        });
      }).toList();
    } catch (e) {
      logger.e('Error getting workouts by date range: $e');
      return [];
    }
  }

  // 총 운동 통계 계산
  Future<Map<String, dynamic>> getTotalStats(String userId) async {
    try {
      final workouts = await getWorkoutHistory(userId, limit: 999);
      
      int totalSquats = 0;
      int totalLunges = 0;
      int totalWalkSteps = 0;
      double totalRunDistance = 0.0;
      int workoutDays = workouts.length;

      for (var workout in workouts) {
        totalSquats += workout.squatCount;
        totalLunges += workout.lungeCount;
        totalWalkSteps += workout.walkSteps;
        totalRunDistance += workout.runDistance;
      }

      return {
        'totalSquats': totalSquats,
        'totalLunges': totalLunges,
        'totalWalkSteps': totalWalkSteps,
        'totalRunDistance': totalRunDistance,
        'workoutDays': workoutDays,
      };
    } catch (e) {
      logger.e('Error calculating total stats: $e');
      return {
        'totalSquats': 0,
        'totalLunges': 0,
        'totalWalkSteps': 0,
        'totalRunDistance': 0.0,
        'workoutDays': 0,
      };
    }
  }

  // ==================== Rankings 업데이트 로직 ====================

  /// rankings 컬렉션 업데이트 (배치에 추가)
  Future<void> _updateRankingsBatch(WriteBatch batch, WorkoutModel workout) async {
    try {
      final userId = workout.userId;
      final date = workout.date;

      // 사용자 정보 조회 (displayName, photoUrl)
      String displayName = '사용자';
      String? photoUrl;
      
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          displayName = userData?['displayName'] ?? '사용자';
          photoUrl = userData?['photoUrl'];
        }
      } catch (e) {
        logger.w('Could not fetch user data, using defaults: $e');
      }

      // 종합 점수 계산
      final overallScore = _calculateOverallScore(workout);

      // 1. 일간 랭킹
      final dailyKey = _formatDate(date, 'yyyy-MM-dd');
      final dailyRef = _firestore
          .collection('rankings')
          .doc('daily')
          .collection(dailyKey)
          .doc(userId);

      batch.set(dailyRef, {
        'squatCount': FieldValue.increment(workout.squatCount),
        'lungeCount': FieldValue.increment(workout.lungeCount),
        'walkSteps': FieldValue.increment(workout.walkSteps),
        'runDistance': FieldValue.increment(workout.runDistance),
        'overallScore': FieldValue.increment(overallScore),
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. 주간 랭킹
      final weekKey = _getWeekKey(date);
      final weeklyRef = _firestore
          .collection('rankings')
          .doc('weekly')
          .collection(weekKey)
          .doc(userId);

      batch.set(weeklyRef, {
        'squatCount': FieldValue.increment(workout.squatCount),
        'lungeCount': FieldValue.increment(workout.lungeCount),
        'walkSteps': FieldValue.increment(workout.walkSteps),
        'runDistance': FieldValue.increment(workout.runDistance),
        'overallScore': FieldValue.increment(overallScore),
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. 월간 랭킹
      final monthKey = _formatDate(date, 'yyyy-MM');
      final monthlyRef = _firestore
          .collection('rankings')
          .doc('monthly')
          .collection(monthKey)
          .doc(userId);

      batch.set(monthlyRef, {
        'squatCount': FieldValue.increment(workout.squatCount),
        'lungeCount': FieldValue.increment(workout.lungeCount),
        'walkSteps': FieldValue.increment(workout.walkSteps),
        'runDistance': FieldValue.increment(workout.runDistance),
        'overallScore': FieldValue.increment(overallScore),
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. 전체 랭킹
      final allTimeRef = _firestore
          .collection('rankings')
          .doc('allTime')
          .collection('users')
          .doc(userId);

      batch.set(allTimeRef, {
        'squatCount': FieldValue.increment(workout.squatCount),
        'lungeCount': FieldValue.increment(workout.lungeCount),
        'walkSteps': FieldValue.increment(workout.walkSteps),
        'runDistance': FieldValue.increment(workout.runDistance),
        'overallScore': FieldValue.increment(overallScore),
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logger.i('📊 Rankings batch prepared: daily=$dailyKey, weekly=$weekKey, monthly=$monthKey');
    } catch (e, stackTrace) {
      logger.e('❌ Error preparing rankings batch: $e');
      logger.e('Stack trace: $stackTrace');
      // rankings 업데이트 실패해도 workout은 저장되도록 에러를 던지지 않음
    }
  }

  /// 종합 점수 계산 (ScoringConfig 사용)
  double _calculateOverallScore(WorkoutModel workout) {
    return ScoringConfig.calculateOverallScore(workout);
  }

  /// 날짜 포맷팅 (yyyy-MM-dd, yyyy-MM)
  String _formatDate(DateTime date, String format) {
    return DateFormat(format).format(date);
  }

  /// 주차 키 생성 (yyyy-MM-dd 형식의 주 시작일)
  String _getWeekKey(DateTime date) {
    // 월요일을 주의 시작으로
    final weekday = date.weekday; // 1(월) ~ 7(일)
    final monday = date.subtract(Duration(days: weekday - 1));
    return _formatDate(monday, 'yyyy-MM-dd');
  }
}

