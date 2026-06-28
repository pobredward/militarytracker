# Firestore 보안 규칙 설정 가이드

## 문제 상황
- 다른 사용자의 프로필을 볼 수 없음
- 에러: `[cloud_firestore/permission-denied] Missing or insufficient permissions`
- 원인: `firestore.rules` 파일이 비어있어 모든 접근이 차단됨

## 해결 방법

### 1. Firestore 보안 규칙 작성
`firestore.rules` 파일에 적절한 보안 규칙을 설정했습니다.

### 2. 배포
```bash
firebase deploy --only firestore:rules
```

## 설정된 보안 규칙

### 📊 Users (사용자 프로필)
```
✅ Read: 모든 사용자 (공개)
✅ Create/Update/Delete: 본인만 가능
```
**이유**: 랭킹, 게시글 작성자 정보 등을 위해 다른 사용자의 프로필을 읽을 수 있어야 함

### 📝 Posts (게시글)
```
✅ Read: 모든 사용자 (공개)
✅ Create: 로그인한 사용자
✅ Update/Delete: 작성자만
```

### 💬 Comments (댓글)
```
✅ Read: 모든 사용자 (공개)
✅ Create: 로그인한 사용자
✅ Update/Delete: 작성자만
```

### 💪 Workouts (운동 기록)
```
✅ Read: 모든 사용자 (랭킹을 위해)
✅ Create/Update/Delete: 본인만
```

### 🏆 Rankings (랭킹)
```
✅ Read: 모든 사용자
❌ Write: Cloud Functions만 (서버측)
```
**이유**: 랭킹 데이터 무결성 보장

### 🎯 Achievements (성취)
```
✅ Read: 모든 사용자
✅ Create/Update/Delete: 본인만
```

### 📈 Statistics (통계)
```
✅ Read: 모든 사용자
✅ Create/Update/Delete: 본인만
```

### 👥 Follows (팔로우)
```
✅ Read: 모든 사용자
✅ Create/Delete: 본인의 팔로우만
```

### 🔔 Notifications (알림)
```
✅ Read/Update: 본인의 알림만
✅ Create: 시스템 또는 다른 사용자
✅ Delete: 본인의 알림만
```

## 보안 원칙

### 1. **공개 읽기 (Public Read)**
- 사용자 프로필
- 게시글, 댓글
- 운동 기록 (랭킹용)
- 랭킹 데이터

**이유**: 
- 커뮤니티 기능
- 랭킹 시스템
- 사용자 간 상호작용

### 2. **본인만 쓰기 (Owner Write)**
- 자신의 데이터만 생성/수정/삭제 가능
- `request.auth.uid` 검증

### 3. **작성자 검증**
```javascript
// 생성 시
request.resource.data.authorId == request.auth.uid

// 수정/삭제 시
resource.data.authorId == request.auth.uid
```

### 4. **서버측 전용 (Server-Only)**
- 랭킹 데이터는 Cloud Functions만 수정 가능
- 데이터 무결성 보장

## 규칙 테스트

### Firebase Console에서 테스트:
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. Firestore Database 선택
3. "규칙" 탭 클릭
4. "규칙 시뮬레이터" 사용

### 예시 테스트:

#### ✅ 다른 사용자 프로필 읽기 (성공해야 함)
```
Operation: get
Location: /users/user123
Auth: Authenticated as user456
Result: ✅ Allow
```

#### ❌ 다른 사용자 프로필 수정 (실패해야 함)
```
Operation: update
Location: /users/user123
Auth: Authenticated as user456
Result: ❌ Deny
```

#### ✅ 자신의 프로필 수정 (성공해야 함)
```
Operation: update
Location: /users/user123
Auth: Authenticated as user123
Result: ✅ Allow
```

## 프로덕션 고려사항

### 현재 설정 (개발/MVP)
```
allow read: if true;  // 모든 사용자가 읽기 가능
```

### 프로덕션 강화 옵션

#### 1. 인증된 사용자만 읽기
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

#### 2. Rate Limiting (읽기 제한)
```javascript
match /users/{userId} {
  allow read: if request.auth != null && 
                 request.time < resource.data.lastRead + duration.value(1, 's');
  // 1초에 1번만 읽기 가능
}
```

#### 3. 민감 정보 보호
```javascript
match /users/{userId} {
  allow read: if true;
  
  // 이메일, 전화번호 등은 본인만
  allow get: if request.auth != null && request.auth.uid == userId;
}
```

#### 4. 필드별 권한
```javascript
match /users/{userId} {
  // 공개 프로필 필드만 읽기
  allow read: if request.auth != null;
  
  // 본인만 전체 정보 접근
  allow get: if request.auth.uid == userId;
  
  // 특정 필드만 업데이트
  allow update: if request.auth.uid == userId &&
                   !request.resource.data.diff(resource.data)
                     .affectedKeys().hasAny(['email', 'uid']);
}
```

## 문제 해결

### 1. 규칙이 적용되지 않을 때
```bash
# 규칙 재배포
firebase deploy --only firestore:rules

# 배포 확인
firebase firestore:rules get
```

### 2. 여전히 권한 에러가 발생할 때
- 브라우저 캐시 삭제
- 앱 재시작
- Firebase Console에서 규칙 확인
- 5-10분 후 재시도 (전파 시간)

### 3. 규칙 문법 에러
```bash
# 로컬에서 규칙 검증
firebase firestore:rules:verify
```

### 4. 디버깅
Firebase Console > Firestore > 규칙 > "규칙 플레이그라운드"에서 테스트

## 참고 문서

- [Firestore 보안 규칙 공식 문서](https://firebase.google.com/docs/firestore/security/get-started)
- [규칙 작성 가이드](https://firebase.google.com/docs/firestore/security/rules-structure)
- [규칙 조건 작성](https://firebase.google.com/docs/firestore/security/rules-conditions)

## 배포 명령어

```bash
# Firestore 규칙만 배포
firebase deploy --only firestore:rules

# 모든 Firebase 리소스 배포
firebase deploy

# 규칙 확인
firebase firestore:rules get
```
