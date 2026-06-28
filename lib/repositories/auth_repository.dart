import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/config/logger.dart';
import '../core/utils/firestore_type_converter.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _collection = 'users';
  
  /// 생성자 주입을 통한 의존성 주입
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  // GoogleSignIn 싱글턴 인스턴스
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  
  // GoogleSignIn 초기화 (더 이상 필요없음 - 생성자에서 처리)
  @Deprecated('GoogleSignIn은 생성자에서 자동으로 초기화됩니다')
  Future<void> initializeGoogleSignIn() async {
    // No-op
  }

  // 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 사용자 정보 가져오기
  Future<UserModel?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return UserModel.fromJson({
        ...data,
        'id': doc.id,
        'createdAt': FirestoreTypeConverter.timestampToIso8601(data['createdAt'], fieldName: 'createdAt'),
        'lastLoginAt': FirestoreTypeConverter.timestampToIso8601(data['lastLoginAt'], fieldName: 'lastLoginAt'),
      });
    } catch (e) {
      logger.e('Error getting user info: $e');
      return null;
    }
  }

  // 사용자 정보 스트림
  Stream<UserModel?> userInfoStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return UserModel.fromJson({
        ...data,
        'id': doc.id,
        'createdAt': FirestoreTypeConverter.timestampToIso8601(data['createdAt'], fieldName: 'createdAt'),
        'lastLoginAt': FirestoreTypeConverter.timestampToIso8601(data['lastLoginAt'], fieldName: 'lastLoginAt'),
      });
    });
  }

  // 이메일 로그인
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateLastLogin(credential.user!.uid);
      return credential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      logger.e('Error signing in: $e');
      rethrow;
    }
  }

  // 이메일 회원가입
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firebase Auth 프로필 업데이트
      await credential.user!.updateDisplayName(displayName);

      // Firestore에 사용자 정보 저장
      await _firestore.collection(_collection).doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'authProvider': 'email',
        'totalSquats': 0,
        'totalLunges': 0,
        'totalWalkSteps': 0,
        'totalRunDistance': 0.0,
        'workoutDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      logger.e('Error signing up: $e');
      rethrow;
    }
  }

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In 지원 여부 확인
      if (!_googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError('Google Sign-In is not supported on this platform');
      }

      // Google 로그인 트리거
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Google 인증 정보 가져오기 (idToken만 사용)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Firebase 자격증명 생성 (idToken만 사용)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장 (신규 사용자인 경우)
      final userDoc = await _firestore
          .collection(_collection)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection(_collection).doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email ?? '',
          'displayName': userCredential.user!.displayName ?? '구글 사용자',
          'photoUrl': userCredential.user!.photoURL,
          'authProvider': 'google',
          'totalSquats': 0,
          'totalLunges': 0,
          'totalWalkSteps': 0,
          'totalRunDistance': 0.0,
          'workoutDays': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      logger.e('Error signing in with Google: $e');
      rethrow;
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.i('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      logger.e('Error sending password reset email: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      logger.i('User signed out');
    } catch (e) {
      logger.e('Error signing out: $e');
      rethrow;
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.uid;
      if (userId != null) {
        // Firestore 사용자 데이터 삭제
        await _firestore.collection(_collection).doc(userId).delete();
        
        // Firebase Auth 계정 삭제
        await currentUser?.delete();
        
        logger.i('User account deleted');
      }
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      logger.e('Error deleting account: $e');
      rethrow;
    }
  }

  // 마지막 로그인 시간 업데이트
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error updating last login: $e');
    }
  }

  // 사용자 통계 업데이트
  Future<void> updateUserStats({
    required String userId,
    required int squatIncrement,
    required int lungeIncrement,
    required int walkStepsIncrement,
    required double runDistanceIncrement,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'totalSquats': FieldValue.increment(squatIncrement),
        'totalLunges': FieldValue.increment(lungeIncrement),
        'totalWalkSteps': FieldValue.increment(walkStepsIncrement),
        'totalRunDistance': FieldValue.increment(runDistanceIncrement),
      });
    } catch (e) {
      logger.e('Error updating user stats: $e');
      rethrow;
    }
  }

  // 운동 일수 증가
  Future<void> incrementWorkoutDays(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'workoutDays': FieldValue.increment(1),
      });
    } catch (e) {
      logger.e('Error incrementing workout days: $e');
      rethrow;
    }
  }

  // 프로필 업데이트
  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? bio,
    bool deletePhoto = false, // 사진 삭제 플래그 추가
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (displayName != null) {
        updates['displayName'] = displayName;
        // Firebase Auth 프로필도 업데이트
        await currentUser?.updateDisplayName(displayName);
      }
      
      // 사진 삭제 처리
      if (deletePhoto) {
        updates['photoUrl'] = FieldValue.delete();
        await currentUser?.updatePhotoURL(null);
      } else if (photoUrl != null) {
        // 사진 업데이트
        updates['photoUrl'] = photoUrl;
        await currentUser?.updatePhotoURL(photoUrl);
      }
      
      if (bio != null) {
        updates['bio'] = bio;
      }
      
      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(userId).update(updates);
        logger.i('Profile updated successfully');
      }
      
      return true;
    } catch (e) {
      logger.e('Error updating profile: $e');
      return false;
    }
  }

  // 프로필 사진 삭제
  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'photoUrl': FieldValue.delete(),
      });
      
      // Firebase Auth 프로필 사진도 삭제
      await currentUser?.updatePhotoURL(null);
      
      logger.i('Profile photo deleted successfully');
      return true;
    } catch (e) {
      logger.e('Error deleting profile photo: $e');
      return false;
    }
  }
}

