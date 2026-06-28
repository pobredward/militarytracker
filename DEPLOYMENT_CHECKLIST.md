# 배포 체크리스트 - v1.0.1

## 📋 배포 전 필수 확인 사항

### 1. 버전 업데이트 ✅
- [x] `pubspec.yaml`: `version: 1.0.1+2`
- [x] `CHANGELOG.md` 작성 완료

### 2. Firebase 설정 ⚠️
- [ ] **Firebase Console에서 보안 규칙 배포 (필수)**
  ```bash
  firebase deploy --only firestore:rules
  ```
  또는 Firebase Console → Firestore → 규칙 탭에서 `firestore.rules` 내용 복사/붙여넣기

- [ ] Firebase Authentication 설정 확인
  - 이메일/비밀번호 로그인 활성화
  - Google 로그인 설정 (클라이언트 ID)

- [ ] Firestore 인덱스 확인
  - `workouts` 컬렉션: `userId` + `date` (descending)
  - `posts` 컬렉션: `createdAt` (descending)
  - `follows` 컬렉션: `followerId`, `followingId`

### 3. 코드 검증
- [x] Lint 오류 확인
  ```bash
  flutter analyze
  ```

- [ ] 빌드 테스트
  ```bash
  # Android
  flutter build apk --release
  
  # iOS (Mac에서만)
  flutter build ios --release
  ```

### 4. 테스트 시나리오

#### 랭킹 시스템
- [ ] 일간/주간/월간/전체 랭킹 조회
- [ ] 카테고리별 랭킹 전환
- [ ] 본인 순위 표시
- [ ] 동점자 순위 처리 확인
- [ ] 사용자 클릭 → 프로필 바텀시트

#### 팔로우 시스템
- [ ] 다른 사용자 팔로우/언팔로우
- [ ] 팔로워/팔로잉 수 업데이트
- [ ] 프로필 화면 통계 표시
- [ ] 연속 운동 일수(Streak) 표시
- [ ] 자기 자신 팔로우 시도 (에러 확인)

#### 홈 화면
- [ ] 주간 진행 현황 차트
- [ ] Quick Actions 네비게이션
- [ ] 실시간 데이터 업데이트

#### 통계 및 업적
- [ ] 총 운동량 정확성
- [ ] Streak 계산 정확성
- [ ] 업적 잠금 해제

#### 커뮤니티
- [ ] 게시글 작성/수정/삭제
- [ ] 좋아요 기능
- [ ] 댓글 기능
- [ ] 작성자 클릭 → 프로필

### 5. 성능 테스트
- [ ] 랭킹 조회 속도 (많은 사용자 데이터)
- [ ] 앱 시작 시간
- [ ] 메모리 사용량
- [ ] 네트워크 사용량

### 6. 보안 테스트
- [ ] 다른 사용자의 운동 기록 접근 차단
- [ ] 본인 데이터만 수정 가능
- [ ] 미인증 사용자 차단
- [ ] 자기 자신 팔로우 차단

### 7. 플랫폼별 설정

#### Android
- [ ] `android/app/build.gradle` 확인
  - `versionCode`: 자동 (pubspec에서 가져옴)
  - `versionName`: 자동 (pubspec에서 가져옴)
  - 서명 키 설정 확인 (`key.properties`)

- [ ] `google-services.json` 최신 버전 확인

- [ ] ProGuard 규칙 (필요시)

#### iOS
- [ ] `ios/Runner/Info.plist` 확인
  - 버전 정보는 자동 (pubspec에서 가져옴)
  - 권한 설명 메시지 확인

- [ ] `GoogleService-Info.plist` 최신 버전 확인

- [ ] 서명 설정 (Xcode)
  - Team 선택
  - Bundle Identifier 확인

### 8. 스토어 준비

#### Google Play Store
- [ ] 앱 이름: "밀리터리트래커" 또는 "Military Tracker"
- [ ] 짧은 설명 (80자 이내)
- [ ] 전체 설명 (4000자 이내)
- [ ] 스크린샷 (최소 2개, 권장 8개)
  - 1080 x 1920px 또는 1080 x 2340px
- [ ] 아이콘 (512 x 512px)
- [ ] 카테고리: 건강/운동
- [ ] 연령 등급
- [ ] 개인정보 처리방침 URL

#### Apple App Store
- [ ] 앱 이름
- [ ] 부제 (30자 이내)
- [ ] 설명 (4000자 이내)
- [ ] 스크린샷
  - iPhone 6.7": 1290 x 2796px
  - iPhone 6.5": 1242 x 2688px
  - iPhone 5.5": 1242 x 2208px
- [ ] 아이콘 (1024 x 1024px, 투명도 없음)
- [ ] 카테고리: 건강 및 피트니스
- [ ] 연령 등급
- [ ] 개인정보 처리방침 URL

### 9. 문서화
- [x] CHANGELOG.md 업데이트
- [x] SYSTEM_AUDIT_REPORT.md 작성
- [x] FOLLOW_SYSTEM_GUIDE.md 작성
- [ ] README.md 업데이트 (선택)

### 10. 배포 명령어

#### Android - AAB (Play Store 권장)
```bash
flutter build appbundle --release
```
출력: `build/app/outputs/bundle/release/app-release.aab`

#### Android - APK (직접 배포용)
```bash
flutter build apk --release --split-per-abi
```
출력: `build/app/outputs/flutter-apk/`

#### iOS
```bash
flutter build ios --release
```
그 후 Xcode에서:
1. Product → Archive
2. Distribute App → App Store Connect

---

## 🚀 배포 후 모니터링

### 1. Firebase Console
- [ ] Firestore 사용량 확인 (읽기/쓰기)
- [ ] Authentication 활성 사용자 수
- [ ] Cloud Storage 사용량

### 2. 앱 성능
- [ ] 크래시 리포트 (Firebase Crashlytics 설정 시)
- [ ] 사용자 피드백
- [ ] 평점 및 리뷰

### 3. 비용 관리
- [ ] Firebase 무료 한도 확인
  - Firestore: 50K 읽기/20K 쓰기/일
  - Storage: 5GB 저장, 1GB/일 다운로드
  - Authentication: 무제한

---

## 📝 주요 개선 사항 (v1.0.1)

### 성능 최적화
- ⚡ 랭킹 시스템 쿼리 90% 감소
- 💾 메모리 관리 개선

### 신규 기능
- 🎯 랭킹 시스템 (일간/주간/월간/전체)
- 👥 팔로우/팔로잉 시스템
- 📊 실시간 통계 및 Streak

### 버그 수정
- 🐛 팔로우 시스템 필드명 오류
- 🔧 데이터 일관성 개선

### 보안
- 🔒 Firestore 보안 규칙 전체 적용

---

## ⚠️ 배포 전 최종 확인

1. [ ] **Firebase 보안 규칙 배포 (필수!)**
2. [ ] 모든 테스트 시나리오 통과
3. [ ] Android/iOS 빌드 성공
4. [ ] 버전 번호 확인 (1.0.1+2)
5. [ ] CHANGELOG.md 최종 검토

---

## 🆘 문제 해결

### 빌드 오류
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase 연결 오류
- `google-services.json` (Android) 확인
- `GoogleService-Info.plist` (iOS) 확인
- 패키지 이름/Bundle ID 일치 확인

### 서명 오류 (Android)
- `key.properties` 파일 확인
- `upload-keystore.jks` 경로 확인

---

**준비 완료 후 배포 진행하세요! 🚀**
