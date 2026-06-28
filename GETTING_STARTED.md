# 밀리터리트래커 실행 가이드

## 빠른 시작

### 1. 프로젝트 설정 확인

프로젝트는 이미 완전히 구성되어 있습니다. 아래 파일들이 제자리에 있는지 확인하세요:

- ✅ `android/app/google-services.json` (Firebase Android 설정)
- ✅ `ios/Runner/GoogleService-Info.plist` (Firebase iOS 설정)
- ✅ `lib/firebase_options.dart` (Firebase 초기화 코드)

### 2. 의존성 설치

```bash
# Flutter 패키지 설치
flutter pub get

# iOS 빌드 시 CocoaPods 설치
cd ios
pod install
cd ..
```

### 3. 연결된 기기 확인

```bash
flutter devices
```

실행 결과 예시:
```
2 connected devices:
iPhone 15 Pro (mobile) • 00008110-xxx • ios • iOS 17.0
sdk gphone64 arm64 (mobile) • emulator-5554 • android • Android 14 (API 34)
```

### 4. 앱 실행

```bash
# 첫 번째로 감지된 기기에서 실행
flutter run

# 특정 기기 선택하여 실행
flutter run -d [device_id]

# 예시: Android 에뮬레이터에서 실행
flutter run -d emulator-5554

# 예시: iPhone 시뮬레이터에서 실행
flutter run -d "iPhone 15 Pro"
```

### 5. 핫 리로드 (개발 중)

앱이 실행 중일 때 터미널에서:
- `r` : 핫 리로드 (빠른 리로드)
- `R` : 핫 리스타트 (완전히 재시작)
- `q` : 앱 종료

## 플랫폼별 상세 가이드

### Android

#### 최소 요구사항
- Android 5.0 (API Level 21) 이상
- Android Studio 설치 (권장)

#### 실제 기기에서 실행
1. Android 기기의 개발자 옵션 활성화
2. USB 디버깅 활성화
3. USB 케이블로 연결
4. `flutter run` 실행

#### 에뮬레이터에서 실행
1. Android Studio 실행
2. AVD Manager에서 에뮬레이터 생성
3. 에뮬레이터 실행
4. `flutter run` 실행

#### APK 빌드
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# 빌드된 파일 위치
# build/app/outputs/flutter-apk/app-release.apk
```

### iOS

#### 최소 요구사항
- iOS 12.0 이상
- Xcode 설치 (macOS 필수)
- Apple Developer 계정 (실제 기기 실행 시)

#### 시뮬레이터에서 실행
1. Xcode 실행
2. Simulator 앱 열기
3. 원하는 iPhone 모델 선택
4. `flutter run` 실행

#### 실제 기기에서 실행
1. Xcode에서 프로젝트 열기 (`ios/Runner.xcworkspace`)
2. Signing & Capabilities에서 Team 선택
3. iPhone을 Mac에 연결
4. `flutter run` 실행

#### iOS 앱 빌드
```bash
# iOS 빌드 (개발용)
flutter build ios --debug

# iOS 빌드 (릴리스용 - Xcode에서 Archive 필요)
flutter build ios --release
```

## 문제 해결

### "Unable to locate Android SDK" 오류
```bash
# Android SDK 경로 설정
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### iOS CocoaPods 관련 오류
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Firebase 초기화 오류
1. `google-services.json`과 `GoogleService-Info.plist`가 올바른 위치에 있는지 확인
2. Firebase Console에서 SHA-1 인증서 등록 (Android)
3. Bundle Identifier 일치 확인 (iOS)

### 의존성 충돌
```bash
# 캐시 클리어 및 재설치
flutter clean
flutter pub get

# iOS
cd ios
pod deintegrate
pod install
cd ..
```

## 개발 팁

### VS Code 사용
1. Flutter 및 Dart 익스텐션 설치
2. `F5`로 디버깅 시작
3. 중단점(Breakpoint) 설정 가능

### Android Studio 사용
1. Flutter 플러그인 설치
2. Run 버튼으로 실행
3. Android Profiler로 성능 모니터링

### 성능 최적화
```bash
# Profile 모드로 실행 (성능 측정)
flutter run --profile

# Release 모드로 실행 (최종 성능)
flutter run --release
```

### 로그 확인
```bash
# Flutter 로그
flutter logs

# Android 로그
adb logcat

# iOS 로그 (Xcode Console 사용)
```

## 다음 단계

현재 앱은 기본 UI 구조만 갖추고 있습니다. 다음 기능들을 구현할 수 있습니다:

1. **Firebase Authentication 연동**
   - Google 로그인
   - Apple 로그인 (iOS)
   - 이메일/비밀번호 로그인

2. **Firestore 데이터베이스 연동**
   - 운동 기록 저장
   - 커뮤니티 게시글 CRUD
   - 실시간 동기화

3. **Cloud Messaging 푸시 알림**
   - 운동 리마인더
   - 커뮤니티 알림

4. **추가 기능**
   - 운동 통계 차트
   - 업적 시스템
   - 사용자 프로필 커스터마이징

## 문의 및 지원

문제가 발생하면 다음을 확인하세요:
- Flutter Doctor: `flutter doctor -v`
- Firebase 설정 상태
- 기기 연결 상태
- Xcode/Android Studio 버전







