# 환경 변수 설정 가이드

## 개요

이 프로젝트는 민감한 정보(API 키, 인증 정보 등)를 환경 변수로 관리합니다.

## 설정 방법

### 1. .env 파일 생성

```bash
cp .env.template .env
```

### 2. 실제 값 입력

`.env` 파일을 열어 실제 값을 입력하세요.

```env
# 예시
FIREBASE_ANDROID_API_KEY=AIzaSyAbc123...
FIREBASE_ANDROID_APP_ID=1:123456789:android:abc123...
```

### 3. .gitignore 확인

`.env` 파일이 `.gitignore`에 포함되어 있는지 확인하세요:

```gitignore
# Environment
.env
.env.local
.env.*.local
```

## Firebase 설정

### 필수 파일

1. **Android**: `android/app/google-services.json`
2. **iOS**: `ios/Runner/GoogleService-Info.plist`
3. **Web**: `lib/firebase_options.dart` (FlutterFire CLI로 생성)

### Firebase 설정 생성

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 설정
flutterfire configure
```

이 명령어를 실행하면 자동으로 다음 파일들이 생성됩니다:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## 환경별 설정

### Development (개발)

```env
APP_NAME=MilitaryTracker (Dev)
ENABLE_DEBUG_LOGGING=true
```

### Production (프로덕션)

```env
APP_NAME=MilitaryTracker
ENABLE_DEBUG_LOGGING=false
```

## 보안 주의사항

⚠️ **절대 Git에 커밋하지 마세요:**
- `.env`
- `google-services.json`
- `GoogleService-Info.plist`
- `firebase_options.dart` (프로젝트에 따라)

✅ **Git에 커밋해도 되는 것:**
- `.env.template`
- `.gitignore`
- 이 가이드 문서

## 환경 변수 사용 예시

### Dart 코드에서 사용

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 환경 변수 로드
await dotenv.load(fileName: ".env");

// 환경 변수 읽기
final apiKey = dotenv.env['FIREBASE_ANDROID_API_KEY'];
final enableLogging = dotenv.env['ENABLE_DEBUG_LOGGING'] == 'true';
```

### 현재 프로젝트에서

현재는 `firebase_options.dart`가 자동 생성되므로 별도의 환경 변수 로딩이 필요 없습니다.

단, **API 키가 포함된 파일은 반드시 `.gitignore`에 추가**하세요!

## 트러블슈팅

### 문제: Firebase 연결 오류

**해결:**
1. `google-services.json` / `GoogleService-Info.plist` 파일 확인
2. Firebase 콘솔에서 앱이 등록되어 있는지 확인
3. SHA-1 인증서 등록 확인 (Android, Google 로그인 시)

```bash
# Android SHA-1 확인
cd android
./gradlew signingReport
```

### 문제: Google Sign-In 실패

**해결:**
1. Firebase Console > Authentication > Sign-in method에서 Google 활성화
2. Android: SHA-1 인증서 등록
3. iOS: URL Schemes 설정 확인

## CI/CD 환경

GitHub Actions 등 CI/CD 환경에서는 **Secrets**로 환경 변수를 관리하세요.

### GitHub Actions 예시

```yaml
env:
  FIREBASE_ANDROID_API_KEY: ${{ secrets.FIREBASE_ANDROID_API_KEY }}
  FIREBASE_IOS_API_KEY: ${{ secrets.FIREBASE_IOS_API_KEY }}
```

## 참고 문서

- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)
- [Firebase Security](https://firebase.google.com/docs/projects/api-keys)
- [환경 변수 베스트 프랙티스](https://12factor.net/config)
