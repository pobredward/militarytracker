# Firebase 설정 가이드

이 문서는 밀리터리트래커 앱의 Firebase 설정 방법을 안내합니다.

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: militarytracker)
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

## 2. Android 앱 등록

1. Firebase 프로젝트 콘솔에서 "Android 앱 추가" 클릭
2. Android 패키지 이름 입력
   - 확인 방법: `android/app/build.gradle` 파일의 `applicationId` 확인
   - 예: `com.example.militarytracker`
3. 앱 닉네임 입력 (선택사항)
4. SHA-1 인증서 지문 입력 (Google 로그인을 위해 필수)
   ```bash
   # 디버그 키스토어의 SHA-1 가져오기
   cd android
   ./gradlew signingReport
   # 또는
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. `google-services.json` 다운로드
6. `android/app/` 폴더에 `google-services.json` 파일 복사

## 3. iOS 앱 등록 (iOS 개발 시)

1. Firebase 프로젝트 콘솔에서 "iOS 앱 추가" 클릭
2. iOS 번들 ID 입력
   - 확인 방법: `ios/Runner.xcodeproj/project.pbxproj` 파일에서 `PRODUCT_BUNDLE_IDENTIFIER` 확인
3. `GoogleService-Info.plist` 다운로드
4. Xcode에서 `ios/Runner/` 폴더에 파일 추가

## 4. Firebase Authentication 활성화

1. Firebase 콘솔에서 "Authentication" 선택
2. "Sign-in method" 탭 클릭
3. 다음 로그인 방법 활성화:
   - **이메일/비밀번호**: 활성화 토글 클릭
   - **Google**: 활성화 토글 클릭
     - 프로젝트 지원 이메일 입력
     - 저장

## 5. Cloud Firestore 설정

1. Firebase 콘솔에서 "Firestore Database" 선택
2. "데이터베이스 만들기" 클릭
3. 보안 규칙 선택:
   - 프로덕션 모드 (권장)
   - 또는 테스트 모드 (개발 중에만)
4. 데이터베이스 위치 선택 (asia-northeast3 권장 - 서울)
5. "완료" 클릭

### Firestore 보안 규칙 설정

Firebase 콘솔의 Firestore Database > 규칙 탭에서 다음 규칙을 설정하세요:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 컬렉션
    match /users/{userId} {
      // 로그인한 사용자만 자신의 데이터를 읽고 쓸 수 있음
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 운동 기록 컬렉션
    match /workouts/{workoutId} {
      // 로그인한 사용자만 자신의 운동 기록을 읽고 쓸 수 있음
      allow read, write: if request.auth != null && 
                          resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
                     request.resource.data.userId == request.auth.uid;
    }
    
    // 게시글 컬렉션
    match /posts/{postId} {
      // 모든 로그인 사용자가 읽을 수 있음
      allow read: if request.auth != null;
      // 작성자만 수정/삭제 가능
      allow update, delete: if request.auth != null && 
                             resource.data.authorId == request.auth.uid;
      // 로그인한 사용자는 게시글 작성 가능
      allow create: if request.auth != null && 
                     request.resource.data.authorId == request.auth.uid;
    }
  }
}
```

## 6. Firestore 인덱스 설정 (선택사항)

효율적인 쿼리를 위해 다음 복합 인덱스를 생성하세요:

1. **workouts 컬렉션**
   - 필드: `userId` (ASC), `date` (DESC)
   - 설명: 사용자별 운동 기록을 날짜순으로 조회

Firebase 콘솔 > Firestore Database > 색인 탭에서 추가할 수 있습니다.

## 7. Firebase CLI 설치 (선택사항)

FlutterFire CLI를 사용하여 자동으로 설정할 수도 있습니다:

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 로그인
firebase login

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 Flutter 앱 연결
flutterfire configure
```

## 8. 환경 변수 설정 (선택사항)

프로덕션과 개발 환경을 분리하려면:

1. Firebase에서 별도의 프로젝트 생성 (예: militarytracker-dev)
2. 각 환경에 맞는 `google-services.json` 파일 준비
3. Build flavor 설정으로 환경 분리

## 9. 테스트

1. 앱 실행
   ```bash
   flutter run
   ```
2. 회원가입 테스트
   - 이메일/비밀번호로 회원가입
   - Google 로그인
3. Firebase 콘솔에서 사용자 확인
   - Authentication > Users 탭에서 사용자 생성 확인
   - Firestore Database에서 `users` 컬렉션 확인
4. 운동 기록 저장 테스트
   - 운동 화면에서 데이터 입력 후 저장
   - Firestore에서 `workouts` 컬렉션 확인

## 10. 문제 해결

### Google 로그인이 작동하지 않는 경우

1. SHA-1 인증서가 올바르게 등록되었는지 확인
2. `google-services.json` 파일이 최신 버전인지 확인
3. 앱을 완전히 삭제 후 재설치

### Firestore 권한 오류

1. Firestore 보안 규칙이 올바르게 설정되었는지 확인
2. 사용자가 로그인되어 있는지 확인
3. Firebase 콘솔의 규칙 탭에서 규칙 시뮬레이터로 테스트

### 빌드 오류

```bash
# 패키지 재설치
flutter clean
flutter pub get

# Android 빌드 캐시 삭제
cd android
./gradlew clean
cd ..

# 다시 실행
flutter run
```

## 데이터 구조

### Users Collection

```
users/{userId}
├── email: string
├── displayName: string
├── photoUrl: string?
├── authProvider: string (email | google)
├── totalSquats: number
├── totalLunges: number
├── totalWalkSteps: number
├── totalRunDistance: number
├── workoutDays: number
├── createdAt: timestamp
└── lastLoginAt: timestamp
```

### Workouts Collection

```
workouts/{workoutId}
├── id: string
├── userId: string
├── squatCount: number
├── lungeCount: number
├── walkSteps: number
├── runDistance: number
├── duration: number
├── notes: string?
├── date: timestamp
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Posts Collection (커뮤니티)

```
posts/{postId}
├── id: string
├── authorId: string
├── authorName: string
├── title: string
├── content: string
├── likes: number
├── comments: number
├── createdAt: timestamp
└── updatedAt: timestamp
```

## 보안 권장사항

1. **프로덕션 빌드 전**:
   - Firestore 보안 규칙을 프로덕션 모드로 변경
   - API 키 제한 설정 (Firebase 콘솔 > 프로젝트 설정 > 일반)
   - 앱 서명 설정

2. **사용자 데이터 보호**:
   - 민감한 정보는 암호화하여 저장
   - 사용자 입력 검증
   - Rate limiting 설정

3. **정기적인 보안 검토**:
   - Firebase 콘솔에서 보안 알림 확인
   - 사용자 행동 모니터링
   - 이상 활동 감지 시 즉시 대응

## 추가 리소스

- [Firebase 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Firebase 보안 규칙 가이드](https://firebase.google.com/docs/rules)





