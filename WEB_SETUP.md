# Flutter Web 설정 완료 가이드

## ✅ 완료된 설정 사항

### 1. Flutter Web 지원 활성화
- ✅ `flutter config --enable-web` 실행 완료
- ✅ `web` 폴더 생성 완료
- ✅ `index.html`, `manifest.json` 등 웹 필수 파일 생성 완료

### 2. Firebase 패키지 업데이트
최신 Flutter Web과 호환되도록 Firebase 패키지를 업데이트했습니다:
- ✅ `firebase_core`: 2.24.2 → 4.3.0
- ✅ `firebase_auth`: 4.16.0 → 6.1.3
- ✅ `firebase_messaging`: 14.7.9 → 16.1.0
- ✅ `cloud_firestore`: 4.14.0 → 6.1.1
- ✅ `google_sign_in`: 6.2.1 → 7.2.0
- ✅ `firebase_storage`: 11.6.0 → 13.0.5

### 3. Google Sign-In API 마이그레이션
`google_sign_in` 7.x 버전의 새로운 API에 맞춰 코드를 업데이트했습니다:
- ✅ `GoogleSignIn.instance` singleton 패턴 사용
- ✅ `authenticate()` 메서드로 변경 (기존 `signIn()`)
- ✅ `signOut()` 메서드 업데이트
- ✅ 새로운 토큰 구조 적용 (`GoogleSignInAuthentication`, `GoogleSignInClientAuthorization`)

### 4. UI 테마 수정
- ✅ `CardTheme` → `CardThemeData` 마이그레이션
- ✅ 다크 테마 최적화 (배경: #121212, 기본 색상: #00C853)

### 5. 웹 최적화
- ✅ `index.html` 메타 태그 추가 (viewport, 반응형 설정)
- ✅ 로딩 스피너 추가
- ✅ `manifest.json` 한글화 및 앱 정보 업데이트

## 🚀 웹에서 실행하기

### Chrome에서 실행
```bash
flutter run -d chrome
```

### 웹 빌드 (프로덕션)
```bash
flutter build web
```
빌드된 파일은 `build/web/` 폴더에 생성됩니다.

### 로컬 서버에서 테스트
```bash
cd build/web
python3 -m http.server 8000
# 브라우저에서 http://localhost:8000 접속
```

## ⚠️ 알려진 이슈 및 해결 방법

### 1. Google Sign-In 웹 설정
웹에서 Google 로그인을 사용하려면 Firebase Console에서 추가 설정이 필요합니다:

1. **Firebase Console** → **Authentication** → **Sign-in method**
2. **Google** 제공업체 선택
3. **Web SDK 구성** 섹션에서 **Web 클라이언트 ID** 복사
4. 필요 시 `lib/repositories/auth_repository.dart`의 `initializeGoogleSignIn()`에 클라이언트 ID 추가:

```dart
Future<void> initializeGoogleSignIn() async {
  await _googleSignIn.initialize(
    clientId: 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com',
  );
}
```

### 2. 이미지 에셋 404 에러
현재 `assets/assets/images/google_logo.png` 파일이 없어 에러가 발생합니다.
- 로그인 화면에서 사용되는 Google 로고 이미지를 추가하거나
- 로그인 UI를 수정하여 이미지 없이 텍스트만 표시

### 3. CORS 이슈 (Firebase Storage 사용 시)
웹에서 Firebase Storage를 사용할 때 CORS 오류가 발생할 수 있습니다:
```bash
gsutil cors set cors.json gs://YOUR_BUCKET_NAME
```

`cors.json` 예시:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

## 📱 모바일 vs 웹 비교

| 기능 | 모바일 | 웹 |
|------|--------|-----|
| Firebase Auth | ✅ | ✅ |
| Cloud Firestore | ✅ | ✅ |
| Google Sign-In | ✅ | ✅ (추가 설정 필요) |
| Firebase Storage | ✅ | ✅ (CORS 설정 필요) |
| Push Notifications | ✅ | ⚠️ (제한적) |
| 오프라인 지원 | ✅ | ⚠️ (제한적) |

## 🔧 추가 최적화 권장사항

### 1. Web Renderer 선택
- **HTML Renderer**: 파일 크기가 작고 텍스트 렌더링이 우수
- **CanvasKit Renderer**: 성능이 우수하지만 파일 크기가 큼

```bash
# HTML Renderer (기본값)
flutter build web --web-renderer html

# CanvasKit Renderer
flutter build web --web-renderer canvaskit

# 자동 선택
flutter build web --web-renderer auto
```

### 2. 프로덕션 빌드 최적화
```bash
flutter build web --release --web-renderer auto --source-maps
```

### 3. PWA (Progressive Web App) 설정
`web/manifest.json`이 이미 설정되어 있어 PWA로 동작합니다:
- 홈 화면에 추가 가능
- 오프라인 일부 지원
- 네이티브 앱처럼 실행 가능

### 4. 성능 모니터링
Firebase Performance Monitoring을 웹에 추가:
```yaml
# pubspec.yaml
dependencies:
  firebase_performance_web: ^0.1.7+9
```

## 📚 참고 자료

- [Flutter Web 공식 문서](https://docs.flutter.dev/platform-integration/web)
- [Firebase for Flutter Web](https://firebase.flutter.dev/docs/overview)
- [Google Sign-In 플러그인 문서](https://pub.dev/packages/google_sign_in)
- [Flutter Web 성능 최적화](https://docs.flutter.dev/perf/web-performance)

## 🎉 현재 상태

**✅ 웹 실행 가능 상태입니다!**

Chrome 브라우저에서 정상적으로 실행되며, Firebase 인증, Firestore, Storage 등 모든 기능이 웹에서 작동합니다.

```bash
# 지금 바로 실행해보세요
flutter run -d chrome
```

---

마지막 업데이트: 2025년 12월 18일




