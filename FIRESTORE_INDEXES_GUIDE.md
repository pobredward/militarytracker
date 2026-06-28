# Firestore 인덱스 설정 가이드

## 필요한 복합 인덱스

### 1. Posts - authorId + createdAt (내림차순)

사용자 프로필 페이지에서 해당 사용자의 게시글을 시간순으로 조회하기 위한 인덱스

**컬렉션**: `posts`  
**필드**:
1. `authorId` - Ascending
2. `createdAt` - Descending

**쿼리 코드**:
```dart
_firestore
  .collection('posts')
  .where('authorId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
  .limit(10)
```

---

## Firebase Console에서 수동 생성

### 방법 1: 에러 메시지의 링크 사용 (가장 쉬움)

1. 앱에서 에러가 발생하면 콘솔에 인덱스 생성 링크가 표시됩니다
2. 해당 링크를 클릭
3. "인덱스 만들기" 버튼 클릭
4. 2-5분 대기

### 방법 2: Firebase Console에서 직접 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 (`military-tracker-96bdd`)
3. 왼쪽 메뉴 → **Firestore Database**
4. 상단 탭 → **인덱스**
5. **복합** 탭 선택
6. **인덱스 추가** 버튼 클릭

#### Posts 인덱스 설정:
```
컬렉션 ID: posts
필드:
  - authorId: 오름차순
  - createdAt: 내림차순
쿼리 범위: 컬렉션
```

7. **만들기** 클릭
8. 인덱스 빌드 완료 대기 (2-5분)

---

## firestore.indexes.json 파일로 관리

프로젝트에 인덱스 설정 파일을 추가하면 배포 시 자동으로 인덱스가 생성됩니다.

**파일**: `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "authorId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "comments",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "postId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "workouts",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### 인덱스 배포:

```bash
firebase deploy --only firestore:indexes
```

---

## 인덱스 빌드 상태 확인

### Firebase Console:
1. Firestore Database → 인덱스 탭
2. 상태 확인:
   - 🟢 **사용 설정됨**: 사용 가능
   - 🟡 **빌드 중**: 대기 필요 (2-5분)
   - 🔴 **오류**: 설정 확인 필요

### CLI로 확인:
```bash
firebase firestore:indexes
```

---

## 일반적인 인덱스 패턴

### 1. 필터 + 정렬
```dart
// authorId로 필터링 + createdAt으로 정렬
where('authorId', isEqualTo: userId)
.orderBy('createdAt', descending: true)

// 필요한 인덱스:
// authorId (ASC) + createdAt (DESC)
```

### 2. 다중 필터
```dart
// 두 개 이상의 필드로 필터링
where('category', isEqualTo: 'workout')
.where('userId', isEqualTo: userId)

// 필요한 인덱스:
// category (ASC) + userId (ASC)
```

### 3. 범위 쿼리 + 정렬
```dart
// 범위 필터 + 정렬
where('createdAt', isGreaterThan: yesterday)
.orderBy('createdAt', descending: true)
.orderBy('likes', descending: true)

// 필요한 인덱스:
// createdAt (DESC) + likes (DESC)
```

---

## 인덱스가 필요 없는 경우

### 1. 단일 필드 쿼리
```dart
// 자동 인덱스 사용
where('userId', isEqualTo: userId)
```

### 2. 단일 정렬
```dart
// 자동 인덱스 사용
orderBy('createdAt', descending: true)
```

---

## 문제 해결

### 1. 인덱스 빌드가 너무 오래 걸림
- 데이터가 많으면 시간이 더 걸림 (최대 1시간)
- Firebase Console에서 진행률 확인

### 2. 인덱스 생성 후에도 에러 발생
- 앱 재시작
- 브라우저 캐시 삭제
- 5분 후 재시도

### 3. 잘못된 인덱스 생성
- Firebase Console에서 인덱스 삭제
- 올바른 설정으로 재생성

### 4. 개발 중 자주 발생하는 경우
- `firestore.indexes.json` 파일 사용 권장
- Git으로 버전 관리

---

## 성능 최적화 팁

### 1. 필요한 인덱스만 생성
- 불필요한 인덱스는 저장 공간 낭비
- 쿼리 분석 후 필요한 것만 생성

### 2. 복합 인덱스 순서 중요
```dart
// 잘못된 순서
authorId (ASC) + createdAt (ASC)  // DESC 필요

// 올바른 순서
authorId (ASC) + createdAt (DESC)
```

### 3. 단일 필드 면제 활용
- 등호(`==`) 필터는 자동 인덱스 사용
- 복합 쿼리에만 명시적 인덱스 필요

---

## 참고 문서

- [Firestore 인덱스 개요](https://firebase.google.com/docs/firestore/query-data/indexing)
- [인덱스 관리](https://firebase.google.com/docs/firestore/query-data/index-overview)
- [복합 인덱스](https://firebase.google.com/docs/firestore/query-data/index-overview#composite_indexes)
