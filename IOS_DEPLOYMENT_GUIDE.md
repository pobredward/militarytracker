# iOS App Store 배포 가이드

## 📋 현재 상태
- ✅ Bundle ID: `com.onmindlabs.militarytracker`
- ✅ Version: 1.0.0 (Build 1)
- ✅ Firebase 설정 완료
- ✅ Info.plist 권한 설정 완료
- ✅ CocoaPods 설치 완료

## 🚀 배포 단계

### 1단계: Xcode에서 프로젝트 열기

```bash
open ios/Runner.xcworkspace
```

⚠️ **중요**: `Runner.xcworkspace`를 열어야 합니다 (`.xcodeproj` 아님!)

---

### 2단계: 서명 및 Capabilities 설정

#### A. Target 선택
1. 좌측 프로젝트 네비게이터에서 **Runner** 프로젝트 클릭
2. **TARGETS** → **Runner** 선택

#### B. Signing & Capabilities 탭
1. **Automatically manage signing** 체크
2. **Team** 선택: 본인의 Apple Developer 팀 선택
3. **Bundle Identifier** 확인: `com.onmindlabs.militarytracker`

#### C. Capabilities 추가 (필수)
다음 Capabilities를 추가해야 합니다:

**추가 방법**: `+ Capability` 버튼 클릭

1. **Push Notifications** 
   - Firebase Cloud Messaging 사용

2. **Background Modes**
   - ✅ Location updates (러닝 GPS 추적)
   - ✅ Remote notifications (푸시 알림)
   - ✅ Background fetch

3. **Sign in with Apple** (선택사항)
   - Google 로그인 사용 중이므로 선택사항

---

### 3단계: iOS Deployment Target 확인

1. **TARGETS** → **Runner** 선택
2. **Build Settings** 탭
3. 검색: `iOS Deployment Target`
4. 값 확인: **16.0** (Podfile과 일치)

만약 **13.0**이라면 **16.0**으로 변경:
- 이유: ML Kit 및 최신 Firebase SDK 요구사항

---

### 4단계: App Store Connect에서 앱 등록

#### A. App Store Connect 로그인
https://appstoreconnect.apple.com

#### B. 새 앱 만들기
1. **나의 앱** → **+ 버튼** → **신규 앱**
2. 정보 입력:
   - **플랫폼**: iOS
   - **이름**: 밀리터리트래커
   - **기본 언어**: 한국어
   - **번들 ID**: `com.onmindlabs.militarytracker`
   - **SKU**: `militarytracker-1.0.0`
   - **사용자 액세스**: 전체 액세스

#### C. 앱 정보 입력
**앱 정보** 탭:
- **카테고리**:
  - 기본: 건강 및 피트니스
  - 보조: 라이프스타일
- **콘텐츠 권한**: 만 4세 이상

**가격 및 사용 가능 여부**:
- 가격: 무료
- 사용 가능한 국가: 대한민국 (또는 전체)

---

### 5단계: iOS 빌드 준비

#### A. 버전 확인
`pubspec.yaml` 파일:
```yaml
version: 1.0.0+1
```
- 1.0.0 = 버전 번호 (사용자에게 표시)
- +1 = 빌드 번호 (App Store Connect 내부용)

#### B. Release 모드로 빌드
터미널에서:
```bash
cd /Users/edwardshin/Desktop/dev/militarytracker
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

---

### 6단계: Archive 생성

#### A. Xcode에서 Archive
1. Xcode 상단 메뉴: **Product** → **Destination** → **Any iOS Device (arm64)**
2. **Product** → **Archive** 클릭
3. 빌드 진행 (5-10분 소요)

#### B. Archive 성공 확인
- **Organizer** 창이 자동으로 열림
- 생성된 Archive 확인

---

### 7단계: App Store Connect 업로드

#### A. Distribute App
1. **Organizer**에서 방금 생성한 Archive 선택
2. **Distribute App** 버튼 클릭
3. **App Store Connect** 선택 → **Next**
4. **Upload** 선택 → **Next**
5. **Automatically manage signing** 선택 → **Next**
6. **Upload** 클릭

#### B. 업로드 진행
- 업로드 진행 (5-10분 소요)
- 완료 후 App Store Connect에서 확인 가능 (처리 시간: 10-30분)

---

### 8단계: App Store Connect에서 빌드 연결

#### A. TestFlight 탭
1. App Store Connect → 해당 앱 → **TestFlight** 탭
2. 업로드한 빌드 확인 (상태: 처리 중 → 제출 준비 완료)
3. **내보내기 규정 문서** 업로드 (암호화 관련)
   - 없음 선택 (Firebase만 사용)

#### B. 앱 스토어 탭
1. **앱 스토어** 탭 → **버전 정보**
2. **빌드** 섹션에서 **+ 빌드 추가**
3. 업로드한 빌드 선택

---

### 9단계: 앱 정보 입력 (완료한 항목)

✅ **개인정보 처리방침** - 이미 입력 완료
✅ **데이터 수집 정보** - 이미 입력 완료  
✅ **연령 등급** - User-Generated Content 선택
✅ **콘텐츠 권한** - No third-party content

**추가 입력 필요**:
- [ ] 스크린샷 (iPhone, iPad)
- [ ] 앱 미리보기 (선택사항)
- [ ] 홍보용 문구 (170자)
- [ ] 설명 (4000자)
- [ ] 키워드
- [ ] 지원 URL
- [ ] 마케팅 URL (선택사항)

---

### 10단계: 스크린샷 준비

#### 필수 크기 (iPhone):
- **6.9" Display** (iPhone 16 Pro Max, 15 Pro Max): 1320 x 2868 px
- **6.7" Display** (iPhone 16 Plus, 15 Plus): 1290 x 2796 px
- **6.5" Display** (iPhone 14 Plus, 13 Pro Max): 1284 x 2778 px
- **5.5" Display** (iPhone 8 Plus): 1242 x 2208 px

#### 스크린샷 개수:
- 최소 3개, 최대 10개

#### 추천 스크린샷:
1. 운동 추적 화면 (메인 기능)
2. 스쿼트/런지 카메라 인식 화면
3. 커뮤니티 화면
4. 통계/기록 화면
5. 로그인/온보딩 화면

---

### 11단계: 심사 제출

#### A. 모든 정보 입력 완료 확인
- ✅ 스크린샷
- ✅ 앱 설명
- ✅ 키워드
- ✅ 지원 URL
- ✅ 빌드 연결
- ✅ 개인정보 처리방침
- ✅ 콘텐츠 등급

#### B. 심사용 정보 입력
**앱 리뷰 정보**:
- 로그인 필요 여부: 예
- 테스트 계정 제공:
  ```
  사용자 이름: test@example.com
  비밀번호: Test1234!
  ```
- 추가 정보: 운동 추적 및 커뮤니티 기능 설명

#### C. 심사 제출
1. **저장** 버튼 클릭
2. **심사용으로 제출** 버튼 클릭
3. 확인 팝업 → **제출** 클릭

---

### 12단계: 심사 대기

#### 심사 프로세스:
1. **심사 대기 중** (Waiting for Review): 1-3일
2. **심사 진행 중** (In Review): 1-2일
3. **승인됨** (Approved) → 자동 출시 또는 수동 출시

#### 심사 거절 시:
- 거절 사유 확인
- 문제 해결
- 새 버전 빌드 후 재제출

---

## 🔥 빠른 명령어 모음

### Xcode 열기
```bash
open /Users/edwardshin/Desktop/dev/militarytracker/ios/Runner.xcworkspace
```

### 프로젝트 정리 및 재빌드
```bash
cd /Users/edwardshin/Desktop/dev/militarytracker
flutter clean
flutter pub get
cd ios
pod install --repo-update
cd ..
```

### iOS 빌드 (Release)
```bash
flutter build ios --release
```

### 터미널에서 Archive (고급)
```bash
cd /Users/edwardshin/Desktop/dev/militarytracker/ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

---

## 🐛 문제 해결

### 1. "No signing certificate found" 오류
**해결**: 
1. Xcode → Preferences → Accounts
2. Apple ID 추가
3. Team 선택 후 "Download Manual Profiles" 클릭

### 2. "Provisioning profile doesn't match" 오류
**해결**:
1. Xcode → Signing & Capabilities
2. "Automatically manage signing" 체크
3. Clean Build Folder (Cmd + Shift + K)
4. 재빌드

### 3. CocoaPods 오류
**해결**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
```

### 4. Firebase 연동 오류
**해결**:
- `ios/Runner/GoogleService-Info.plist` 파일 확인
- Bundle ID가 Firebase Console과 일치하는지 확인

### 5. Build 번호 충돌
**해결**:
`pubspec.yaml`에서 빌드 번호 증가:
```yaml
version: 1.0.0+2  # +1 → +2로 변경
```

---

## 📱 앱 설명 (App Store용)

### 짧은 설명 (홍보용 문구)
```
군사 훈련을 스마트하게! AI 자세 인식으로 운동을 자동 카운팅하고, 커뮤니티와 함께 목표를 달성하세요.
```

### 긴 설명
```
밀리터리트래커는 군인과 운동을 즐기는 모든 분들을 위한 스마트 트레이닝 앱입니다.

🎯 주요 기능

• AI 자세 인식
  - 카메라를 통해 스쿼트, 런지 자세를 실시간 분석
  - 정확한 자세로 운동했을 때만 카운트
  - ML Kit 기반의 정확한 포즈 감지

• 다양한 운동 추적
  - 스쿼트, 런지: AI 자동 카운팅
  - 걷기: 만보기 센서로 자동 측정
  - 러닝: GPS 기반 거리 및 속도 추적

• 커뮤니티
  - 운동 기록 공유
  - 동기부여 게시글
  - 좋아요 및 댓글 기능

• 통계 및 기록
  - 일별/주별/월별 운동 기록
  - 목표 달성률 확인
  - 진행 상황 시각화

• 푸시 알림
  - 운동 리마인더
  - 커뮤니티 알림

🏋️ 이런 분들께 추천합니다
- 군 입대 준비생
- 현역 군인
- 규칙적인 운동을 원하는 분
- 운동 동기부여가 필요한 분

💪 지금 바로 시작하세요!
밀리터리트래커와 함께 더 강해지는 자신을 발견하세요.
```

### 키워드
```
군대,운동,트래킹,피트니스,스쿼트,런지,러닝,만보기,AI,자세인식,커뮤니티,헬스,건강,트레이닝,워크아웃
```

---

## ✅ 체크리스트

### 배포 전
- [ ] Xcode에서 서명 설정 완료
- [ ] Capabilities 추가 (Push Notifications, Background Modes)
- [ ] iOS Deployment Target 16.0 확인
- [ ] GoogleService-Info.plist 확인
- [ ] Info.plist 권한 설명 확인

### App Store Connect
- [ ] 앱 등록 완료
- [ ] 스크린샷 업로드 (최소 3개)
- [ ] 앱 설명 작성
- [ ] 키워드 입력
- [ ] 지원 URL 입력
- [ ] 개인정보 처리방침 URL 입력

### 빌드 및 업로드
- [ ] Archive 생성 성공
- [ ] App Store Connect 업로드 완료
- [ ] TestFlight에서 빌드 확인
- [ ] 앱 스토어 탭에서 빌드 연결

### 심사 제출
- [ ] 심사용 테스트 계정 제공
- [ ] 추가 정보 입력
- [ ] 심사 제출

---

## 🔗 유용한 링크

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase Console](https://console.firebase.google.com)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

## 📞 문의

문제가 발생하면 다음을 확인하세요:
1. Xcode 버전: 최신 버전 사용 권장
2. Flutter 버전: `flutter doctor` 실행
3. CocoaPods 버전: `pod --version`
4. iOS SDK 버전: Xcode에서 확인

