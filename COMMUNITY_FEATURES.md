# 커뮤니티 기능 가이드

## 📱 구현된 기능

### 1. 게시글 관리
- ✅ 게시글 작성
- ✅ 게시글 목록 조회
- ✅ 게시글 상세 보기
- ✅ 게시글 수정 (작성자만)
- ✅ 게시글 삭제 (작성자만)
- ✅ 좋아요 기능
- ✅ 실시간 업데이트 (Firestore Stream)

### 2. 댓글 기능
- ✅ 댓글 작성
- ✅ 댓글 목록 조회
- ✅ 댓글 삭제 (작성자만)
- ✅ 실시간 댓글 업데이트

### 3. 미디어 지원 (준비 완료)
- 🔜 이미지 업로드
- 🔜 동영상 업로드
- 📦 데이터 모델에 `imageUrls`, `videoUrls` 필드 추가됨

## 🏗️ 데이터 구조

### PostModel
```dart
class PostModel {
  String id;                    // 게시글 ID
  String authorId;              // 작성자 ID
  String authorName;            // 작성자 이름
  String? authorPhotoUrl;       // 작성자 프로필 사진
  String title;                 // 제목
  String content;               // 내용
  List<String> imageUrls;       // 이미지 URL 목록 (추후 사용)
  List<String> videoUrls;       // 동영상 URL 목록 (추후 사용)
  int likes;                    // 좋아요 수
  List<String> likedBy;         // 좋아요 누른 사용자 ID 목록
  int comments;                 // 댓글 수
  DateTime? createdAt;          // 생성 시간
  DateTime? updatedAt;          // 수정 시간
}
```

### CommentModel
```dart
class CommentModel {
  String id;                    // 댓글 ID
  String postId;                // 게시글 ID
  String authorId;              // 작성자 ID
  String authorName;            // 작성자 이름
  String? authorPhotoUrl;       // 작성자 프로필 사진
  String content;               // 내용
  int likes;                    // 좋아요 수
  List<String> likedBy;         // 좋아요 누른 사용자 ID 목록
  DateTime? createdAt;          // 생성 시간
  DateTime? updatedAt;          // 수정 시간
}
```

## 📂 파일 구조

```
lib/
├── models/
│   ├── post_model.dart           # 게시글 모델
│   └── comment_model.dart        # 댓글 모델
├── repositories/
│   ├── post_repository.dart      # 게시글 저장소
│   └── comment_repository.dart   # 댓글 저장소
├── providers/
│   ├── post_provider.dart        # 게시글 Provider
│   └── comment_provider.dart     # 댓글 Provider
└── features/community/presentation/
    ├── community_screen.dart     # 커뮤니티 메인 화면
    ├── post_detail_screen.dart   # 게시글 상세 화면
    ├── create_post_screen.dart   # 게시글 작성 화면
    └── edit_post_screen.dart     # 게시글 수정 화면
```

## 🎯 주요 기능 설명

### 게시글 작성
1. 커뮤니티 화면에서 **+** 버튼 클릭
2. 제목과 내용 입력 (제목 2자 이상, 내용 10자 이상)
3. **완료** 버튼으로 게시글 작성
4. Firestore에 자동 저장 및 실시간 반영

### 게시글 상세 보기
1. 게시글 카드 클릭
2. 전체 내용, 좋아요, 댓글 확인
3. 댓글 작성 가능
4. 작성자인 경우 수정/삭제 가능

### 게시글 수정/삭제
1. 게시글 상세 화면에서 **⋮** 메뉴 클릭
2. **수정**: 제목과 내용 수정 후 저장
3. **삭제**: 확인 후 영구 삭제

### 좋아요 기능
- ❤️ 버튼 클릭으로 좋아요/취소
- 중복 좋아요 방지 (`likedBy` 배열로 관리)
- 실시간 좋아요 수 업데이트

### 댓글 기능
1. 게시글 하단 입력창에 댓글 작성
2. **전송** 버튼으로 댓글 등록
3. 작성자는 자신의 댓글 삭제 가능
4. 실시간 댓글 업데이트

## 🔐 권한 관리

### 작성자 권한
- ✅ 자신의 게시글 수정
- ✅ 자신의 게시글 삭제
- ✅ 자신의 댓글 삭제

### 일반 사용자 권한
- ✅ 모든 게시글 조회
- ✅ 게시글 작성
- ✅ 좋아요
- ✅ 댓글 작성
- 🔜 신고 기능 (추후 구현)

## 🚀 추후 구현 예정

### 1. 미디어 업로드
```dart
// 이미지 업로드
- Firebase Storage 연동
- 이미지 압축 및 최적화
- 다중 이미지 업로드 (최대 5장)
- 이미지 갤러리 뷰

// 동영상 업로드
- 동영상 압축
- 썸네일 자동 생성
- 재생 컨트롤
```

### 2. 고급 기능
- 🔜 게시글 검색
- 🔜 해시태그
- 🔜 카테고리 분류 (운동 팁, 식단, 동기부여 등)
- 🔜 인기 게시글
- 🔜 북마크
- 🔜 신고 및 관리 기능

### 3. 소셜 기능
- 🔜 사용자 프로필 페이지
- 🔜 팔로우/팔로워
- 🔜 멘션 (@username)
- 🔜 알림 시스템

## 📊 Firestore 구조

### posts 컬렉션
```
posts/
  {postId}/
    - id: string
    - authorId: string
    - authorName: string
    - authorPhotoUrl: string?
    - title: string
    - content: string
    - imageUrls: string[]
    - videoUrls: string[]
    - likes: number
    - likedBy: string[]
    - comments: number
    - createdAt: timestamp
    - updatedAt: timestamp
```

### comments 컬렉션
```
comments/
  {commentId}/
    - id: string
    - postId: string
    - authorId: string
    - authorName: string
    - authorPhotoUrl: string?
    - content: string
    - likes: number
    - likedBy: string[]
    - createdAt: timestamp
    - updatedAt: timestamp
```

## 🎨 UI/UX 특징

### 다크 모드 디자인
- 배경: `#121212`
- 카드: `#1E1E1E`
- 테두리: `#2A2A2A`
- 강조색: `#00C853` (초록)

### 인터랙션
- 실시간 업데이트 (Firestore Stream)
- Pull-to-refresh
- 부드러운 애니메이션
- 직관적인 아이콘

### 반응형
- 다양한 화면 크기 지원
- 키보드 자동 조절
- 스크롤 최적화

## 💡 사용 팁

### 게시글 작성
- 제목은 간결하고 명확하게
- 내용은 구체적으로 작성
- 운동 경험, 팁, 목표 공유

### 댓글 작성
- 건설적인 피드백
- 응원과 격려
- 질문과 답변

### 좋아요
- 도움이 된 게시글에 좋아요
- 동기부여가 되는 내용에 좋아요

## 🔧 개발자 가이드

### 새 게시글 생성
```dart
final newPost = PostModel(
  authorId: userId,
  authorName: userName,
  title: '제목',
  content: '내용',
);

await ref.read(postRepositoryProvider).createPost(newPost);
ref.invalidate(postsProvider); // 목록 새로고침
```

### 댓글 작성
```dart
final newComment = CommentModel(
  postId: postId,
  authorId: userId,
  authorName: userName,
  content: '댓글 내용',
);

await ref.read(commentRepositoryProvider).createComment(newComment);
```

### 좋아요 토글
```dart
final isLiked = post.likedBy.contains(userId);
await ref.read(postRepositoryProvider).toggleLike(
  postId,
  userId,
  isLiked,
);
```

## 🐛 알려진 제한사항

1. **미디어 업로드 미구현**
   - 현재는 텍스트만 지원
   - 이미지/동영상 필드는 준비되어 있음

2. **검색 기능 없음**
   - 전체 게시글만 조회 가능
   - 추후 Algolia 또는 Firestore 쿼리 추가 예정

3. **페이지네이션 미구현**
   - 현재는 최신 20개만 로드
   - 무한 스크롤 추가 예정

## 📚 참고 자료

- [Firestore 문서](https://firebase.google.com/docs/firestore)
- [Riverpod 문서](https://riverpod.dev)
- [Freezed 문서](https://pub.dev/packages/freezed)




