# GoogleSignIn API 7.2.0 최종 수정 완료

> 작성일: 2026-03-23  
> 상태: ✅ 완료

## 📋 문제

`google_sign_in` 7.2.0에서 API가 완전히 변경되어 기존 코드가 작동하지 않음.

## 🔧 최종 해결 방법

### 변경된 API

#### 1. GoogleSignIn 초기화
```dart
// OLD (동작 안함)
final GoogleSignIn _googleSignIn = GoogleSignIn();

// NEW (7.2.0)
GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
```

#### 2. 로그인 메서드
```dart
// OLD
final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

// NEW
final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
```

#### 3. 인증 토큰
```dart
// OLD
final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,  // 없어짐!
  idToken: googleAuth.idToken,
);

// NEW
final GoogleSignInAuthentication googleAuth = googleUser.authentication; // await 불필요
final credential = GoogleAuthProvider.credential(
  idToken: googleAuth.idToken,  // idToken만 사용
);
```

### 주요 변경 사항

1. **싱글턴 패턴**: `GoogleSignIn.instance` 사용
2. **authenticate() 메서드**: `signIn()` 대신 사용
3. **authentication 필드**: `await` 불필요 (동기)
4. **accessToken 제거**: `idToken`만 사용
5. **null 안정성**: `authenticate()`는 항상 결과 반환 (null 불가)

### 코드 예시

```dart
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 플랫폼 지원 확인
      if (!_googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError('Google Sign-In is not supported');
      }

      // 인증 (항상 GoogleSignInAccount 반환)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 토큰 가져오기 (await 불필요)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Firebase 자격증명 (idToken만 사용)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      logger.e('Google sign-in failed', e);
      rethrow;
    }
  }
}
```

## ✅ 해결 완료

- ✅ GoogleSignIn 초기화 방식 변경
- ✅ authenticate() 메서드 사용
- ✅ accessToken 제거, idToken만 사용
- ✅ await 불필요한 부분 제거
- ✅ null 안정성 개선
- ✅ 플랫폼 지원 확인 추가

## 📚 참고 문서

- [google_sign_in 7.2.0 문서](https://pub.dev/packages/google_sign_in)
- [Migration Guide](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/MIGRATION.md)
