# iOS 배포 준비 완료! 🍎

## ✅ 버전 설정 완료

### 변경 사항
- **이전**: `version: 1.0.4+4`
- **현재**: `version: 1.0.0+1`

---

## 📱 iOS 배포 버전 정보

### pubspec.yaml
```yaml
version: 1.0.0+1
```

이것은 다음을 의미합니다:
- **버전 이름 (CFBundleShortVersionString)**: `1.0.0`
- **빌드 번호 (CFBundleVersion)**: `1`

### Info.plist (자동 적용)
```xml
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>  <!-- 1.0.0 -->

<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>  <!-- 1 -->
```

---

## 🚀 iOS 배포 단계

### 1. Xcode에서 빌드 준비

```bash
# iOS 빌드 실행
cd /Users/edwardshin/Desktop/dev/militarytracker
flutter build ios --release
```

### 2. Xcode 열기

```bash
open ios/Runner.xcworkspace
```

### 3. Xcode에서 확인할 사항

#### ✅ General 탭
- **Display Name**: 밀리터리트래커
- **Bundle Identifier**: com.yourcompany.militarytracker (또는 실제 번들 ID)
- **Version**: 1.0.0
- **Build**: 1

#### ✅ Signing & Capabilities
- [x] Automatically manage signing (체크)
- [x] Team 선택 (Apple Developer 계정)
- [x] Provisioning Profile 확인

#### ✅ Build Settings
- **iOS Deployment Target**: 12.0 이상 권장
- **Supported Platforms**: iOS
- **Architectures**: arm64 (실제 기기용)

### 4. Archive 생성

1. Xcode 메뉴: **Product → Archive**
2. Archive 완료 대기
3. Organizer 창이 자동으로 열림

### 5. App Store Connect에 업로드

1. Organizer에서 Archive 선택
2. **Distribute App** 클릭
3. **App Store Connect** 선택
4. **Upload** 선택
5. 옵션 확인 후 **Next**
6. 서명 확인 후 **Upload**

### 6. App Store Connect에서 확인

1. https://appstoreconnect.apple.com 로그인
2. **My Apps** 선택
3. 밀리터리트래커 앱 선택
4. **Activity** 탭에서 빌드 확인
5. 처리 완료 대기 (10-30분)

---

## 🔍 버전 확인 명령어

### Flutter 버전 확인
```bash
cd /Users/edwardshin/Desktop/dev/militarytracker
grep version pubspec.yaml
# 출력: version: 1.0.0+1
```

### iOS 프로젝트 버전 확인
```bash
cd ios
grep -A 1 "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" Runner.xcodeproj/project.pbxproj
```

---

## 📋 iOS 배포 체크리스트

### 코드 준비
- [x] **버전 번호**: 1.0.0+1로 설정 완료
- [x] **Flutter clean** 실행 완료
- [x] **Dependencies** 설치 완료
- [ ] **테스트**: 실제 iOS 기기에서 테스트
- [ ] **빌드**: `flutter build ios --release` 실행

### Apple Developer 계정
- [ ] **Apple Developer Program 가입** 확인
- [ ] **Bundle ID 등록** (App Identifiers)
- [ ] **Certificates 생성** (Distribution Certificate)
- [ ] **Provisioning Profile 생성**

### App Store Connect
- [ ] **앱 등록** (처음이면 새로 생성)
- [ ] **앱 정보 입력**:
  - 이름: 밀리터리트래커
  - 카테고리: 건강 및 피트니스
  - 스크린샷 준비
  - 설명 작성
  - 키워드 설정
- [ ] **개인정보 보호정책 URL** 준비
- [ ] **지원 URL** 준비

### 앱 권한 (이미 Info.plist에 설정됨)
- [x] **카메라 권한** (NSCameraUsageDescription)
- [x] **위치 권한** (NSLocationWhenInUseUsageDescription)
- [x] **모션 권한** (NSMotionUsageDescription)
- [x] **백그라운드 모드** (location, fetch, remote-notification)

### Firebase 설정
- [x] **GoogleService-Info.plist** 확인
- [x] **Bundle ID 일치** 확인

---

## 🎯 배포 명령어

### 전체 프로세스 (순서대로)

```bash
# 1. 프로젝트 디렉토리로 이동
cd /Users/edwardshin/Desktop/dev/militarytracker

# 2. 빌드 정리 (이미 완료)
# flutter clean

# 3. iOS 릴리즈 빌드
flutter build ios --release

# 4. Xcode 열기
open ios/Runner.xcworkspace

# 5. Xcode에서:
#    - Product → Archive
#    - Distribute App → App Store Connect
#    - Upload
```

---

## ⚠️ 주의사항

### 1. Bundle Identifier
- Xcode에서 Bundle ID가 Firebase 프로젝트와 일치하는지 확인
- 현재 설정: `com.yourcompany.militarytracker` (변경 필요할 수 있음)

### 2. Team 설정
- Xcode의 Signing & Capabilities에서 Team 선택 필수
- Apple Developer Program 계정이 있어야 함

### 3. 첫 배포
- 처음 배포하는 경우 App Store Connect에서 앱을 먼저 생성해야 함
- Bundle ID는 한 번 설정하면 변경 불가

### 4. 빌드 번호
- 다음 배포 시 빌드 번호를 증가시켜야 함
- 예: `1.0.0+2`, `1.0.0+3`, ...
- 버전 업데이트 시: `1.0.1+1`, `1.1.0+1`, ...

---

## 🆘 문제 해결

### 빌드 실패 시
```bash
# Pod 재설치
cd ios
pod deintegrate
pod install
cd ..

# Flutter 재빌드
flutter clean
flutter pub get
flutter build ios --release
```

### Signing 에러 시
1. Xcode → Preferences → Accounts
2. Apple ID 로그인 확인
3. Signing & Capabilities → Team 다시 선택

### Archive 실패 시
1. Generic iOS Device 선택 확인
2. Build Settings → Architectures 확인
3. Provisioning Profile 재생성

---

## 📱 테스트 방법

### 실제 기기에서 테스트
```bash
# 디버그 모드로 기기에 설치
flutter run --release -d [기기 ID]

# 기기 ID 확인
flutter devices
```

### TestFlight 배포
1. App Store Connect에서 빌드 선택
2. TestFlight 탭으로 이동
3. 내부 테스터 추가
4. 빌드 제출
5. 테스터에게 앱 다운로드 링크 전송

---

## ✅ 준비 완료!

**현재 상태**:
- ✅ 버전 1.0.0+1로 설정 완료
- ✅ Flutter 프로젝트 정리 완료
- ✅ Dependencies 설치 완료
- ✅ iOS 권한 설정 완료

**다음 단계**:
```bash
flutter build ios --release
open ios/Runner.xcworkspace
```

그리고 Xcode에서 Archive → Upload 진행하시면 됩니다! 🚀
