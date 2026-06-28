import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../core/utils/result.dart';
import '../core/config/logger.dart';

// AuthRepository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// 현재 Firebase User Provider (Stream)
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// 현재 UserModel Provider (Stream)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final authRepository = ref.watch(authRepositoryProvider);
      return authRepository.userInfoStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// 로그인 상태 Provider
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// Auth Action Provider (로그인, 회원가입 등의 액션 처리)
final authActionProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

class AuthActions {
  final Ref ref;
  
  AuthActions(this.ref);
  
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  
  /// 이메일 로그인 (Result 패턴)
  /// 
  /// Returns:
  ///   - Success<UserCredential>: 로그인 성공
  ///   - Failure: 로그인 실패 (사유 포함)
  Future<Result<UserCredential>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final result = await _authRepository.signInWithEmail(email, password);
      if (result == null) {
        return const Failure('로그인에 실패했습니다.');
      }
      logger.i('Email sign-in successful for: $email');
      return Success(result);
    } on FirebaseAuthException catch (e) {
      final message = _handleAuthException(e);
      AppLogger.e('Email sign-in failed', e);
      return Failure(message, e);
    } catch (e) {
      AppLogger.e('Unknown error during sign-in', e);
      return Failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }
  
  /// 이메일 회원가입 (Result 패턴)
  /// 
  /// Returns:
  ///   - Success<UserCredential>: 회원가입 성공
  ///   - Failure: 회원가입 실패 (사유 포함)
  Future<Result<UserCredential>> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final result = await _authRepository.signUpWithEmail(
        email,
        password,
        displayName,
      );
      if (result == null) {
        return const Failure('회원가입에 실패했습니다.');
      }
      logger.i('Email sign-up successful for: $email');
      return Success(result);
    } on FirebaseAuthException catch (e) {
      final message = _handleAuthException(e);
      AppLogger.e('Email sign-up failed', e);
      return Failure(message, e);
    } catch (e) {
      AppLogger.e('Unknown error during sign-up', e);
      return Failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }
  
  /// Google 로그인 (Result 패턴)
  /// 
  /// Returns:
  ///   - Success<UserCredential>: 로그인 성공
  ///   - Failure: 로그인 실패 또는 취소
  Future<Result<UserCredential>> signInWithGoogle() async {
    try {
      final result = await _authRepository.signInWithGoogle();
      if (result == null) {
        logger.i('Google sign-in cancelled by user');
        return const Failure('로그인이 취소되었습니다.');
      }
      logger.i('Google sign-in successful');
      return Success(result);
    } on FirebaseAuthException catch (e) {
      final message = _handleAuthException(e);
      AppLogger.e('Google sign-in failed', e);
      return Failure(message, e);
    } catch (e) {
      AppLogger.e('Unknown error during Google sign-in', e);
      return Failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }
  
  /// 비밀번호 재설정 이메일 전송 (Result 패턴)
  /// 
  /// Returns:
  ///   - Success<void>: 이메일 전송 성공
  ///   - Failure: 전송 실패
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      logger.i('Password reset email sent to: $email');
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      final message = _handleAuthException(e);
      AppLogger.e('Failed to send password reset email', e);
      return Failure(message, e);
    } catch (e) {
      AppLogger.e('Unknown error sending password reset', e);
      return Failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }
  
  /// 로그아웃 (Result 패턴)
  /// 
  /// Returns:
  ///   - Success<void>: 로그아웃 성공
  ///   - Failure: 로그아웃 실패
  Future<Result<void>> signOut() async {
    try {
      await _authRepository.signOut();
      logger.i('User signed out successfully');
      return const Success(null);
    } catch (e) {
      AppLogger.e('Error during sign out', e);
      return Failure('로그아웃에 실패했습니다: $e');
    }
  }
  
  /// 계정 삭제 (Result 패턴)
  /// 
  /// Returns:
  ///   - Success<void>: 삭제 성공
  ///   - Failure: 삭제 실패
  Future<Result<void>> deleteAccount() async {
    try {
      await _authRepository.deleteAccount();
      logger.i('User account deleted successfully');
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      final message = _handleAuthException(e);
      AppLogger.e('Failed to delete account', e);
      return Failure(message, e);
    } catch (e) {
      AppLogger.e('Unknown error deleting account', e);
      return Failure('알 수 없는 오류가 발생했습니다: $e');
    }
  }
  
  // Firebase Auth 예외 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '이 로그인 방법은 현재 사용할 수 없습니다.';
      case 'requires-recent-login':
        return '이 작업을 수행하려면 다시 로그인해야 합니다.';
      case 'invalid-credential':
        return '인증 정보가 올바르지 않습니다.';
      case 'account-exists-with-different-credential':
        return '이미 다른 로그인 방법으로 등록된 이메일입니다.';
      default:
        return '인증 오류: ${e.message ?? e.code}';
    }
  }
}