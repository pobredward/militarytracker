# 커뮤니티 이미지 업로드 실패 문제 해결

## 🔍 문제 분석

### 발견된 주요 문제점

1. **Firestore Security Rules 불일치** ⚠️
   - Rules에서 `userId` 필드를 체크하는데 실제 데이터는 `authorId` 사용
   - 결과: Firestore에 게시글 저장 시 권한 거부

2. **PostModel의 id 필드 처리 문제**
   - `toJson()`에서 빈 문자열 `id: ''`가 Firestore에 저장됨
   - Firestore는 자동으로 ID를 생성하므로 불필요

3. **에러 로깅 부족**
   - Storage 업로드와 Firestore 저장 과정의 에러가 제대로 로깅되지 않음
   - 실패 원인 파악이 어려움

4. **사용자 피드백 부족**
   - 이미지 업로드 진행 상태 표시 없음
   - 구체적인 에러 메시지 부족

## 🛠️ 해결 방법

### 1. Firestore Security Rules 수정

**파일**: `firestore.rules`

#### Before
```javascript
function isValidPost() {
  let post = request.resource.data;
  return post.keys().hasAll(['userId', 'authorName', 'title', 'content'])
    && post.userId == request.auth.uid
    && isValidString(post.title, 1, 200)
    && isValidString(post.content, 1, 5000);
}

// Posts Collection
match /posts/{postId} {
  allow update: if isSignedIn() && (
    (resource.data.userId == request.auth.uid && isValidPost())
    || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'likedBy', 'comments']))
  );
  allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
}
```

#### After
```javascript
function isValidPost() {
  let post = request.resource.data;
  return post.keys().hasAll(['authorId', 'authorName', 'title', 'content'])
    && post.authorId == request.auth.uid
    && isValidString(post.title, 1, 200)
    && isValidString(post.content, 1, 5000);
}

// Posts Collection
match /posts/{postId} {
  allow update: if isSignedIn() && (
    (resource.data.authorId == request.auth.uid && isValidPost())
    || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'likedBy', 'comments']))
  );
  allow delete: if isSignedIn() && resource.data.authorId == request.auth.uid;
}
```

**변경사항**:
- `userId` → `authorId`로 전체 변경
- Comment 검증 함수의 오타 수정 (`post.content` → `comment.content`)

---

### 2. PostRepository 개선

**파일**: `lib/repositories/post_repository.dart`

#### 주요 개선사항

```dart
Future<String?> createPost(PostModel post) async {
  try {
    logger.i('Creating post with title: "${post.title}"');
    logger.i('Author ID: ${post.authorId}');
    logger.i('Image URLs count: ${post.imageUrls.length}');
    
    final data = post.toJson();
    
    // ✅ ID 필드 제거 (Firestore가 자동 생성)
    data.remove('id');
    
    // Timestamp 설정
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    logger.d('Post data to be saved: ${data.keys.toList()}');

    final docRef = await _firestore.collection(_collection).add(data);
    logger.i('Post created successfully with ID: ${docRef.id}');
    return docRef.id;
  } catch (e, stackTrace) {
    logger.e('Error creating post: $e');
    logger.e('Stack trace: $stackTrace');
    return null;
  }
}
```

**개선사항**:
- ✅ `id` 필드 명시적 제거
- ✅ 상세한 로깅 추가 (제목, 작성자 ID, 이미지 개수)
- ✅ stackTrace 포함한 에러 로깅
- ✅ 저장될 데이터 키 로깅

---

### 3. StorageService 강화

**파일**: `lib/services/storage_service.dart`

#### 이미지 압축 로깅
```dart
Future<File?> compressImage(File file) async {
  try {
    logger.d('Starting image compression for: ${file.path}');
    
    // ... 압축 로직 ...
    
    if (result != null) {
      final originalSize = await file.length();
      final compressedSize = await File(result.path).length();
      final compressionRatio = (1 - compressedSize / originalSize) * 100;
      
      logger.i('Image compressed successfully');
      logger.i('Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      logger.i('Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      logger.i('Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');
      
      return File(result.path);
    }
    
    logger.w('Image compression returned null result');
    return null;
  } catch (e, stackTrace) {
    logger.e('Error compressing image: $e');
    logger.e('Stack trace: $stackTrace');
    return null;
  }
}
```

#### 이미지 업로드 로깅
```dart
Future<String?> uploadPostImage(File file, String userId) async {
  try {
    logger.i('Starting image upload for user: $userId');
    logger.i('Image file path: ${file.path}');
    logger.i('Image file size: ${await file.length()} bytes');
    
    // 파일 존재 확인
    if (!await file.exists()) {
      logger.e('File does not exist: ${file.path}');
      return null;
    }
    
    // 압축
    logger.d('Compressing image...');
    final compressedFile = await compressImage(file);
    if (compressedFile == null) {
      logger.e('Image compression failed');
      return null;
    }
    
    logger.i('Image compressed: ${await compressedFile.length()} bytes');

    // 업로드
    final fileName = '${_uuid.v4()}.jpg';
    final storagePath = 'posts/$userId/$fileName';
    final ref = _storage.ref().child(storagePath);
    
    logger.d('Storage path: $storagePath');
    logger.d('Starting Firebase Storage upload...');
    
    final uploadTask = ref.putFile(compressedFile, metadata);
    
    // 진행률 모니터링
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
      logger.d('Upload progress: ${progress.toStringAsFixed(1)}%');
    });
    
    final snapshot = await uploadTask;
    logger.i('Upload completed. State: ${snapshot.state}');

    // URL 가져오기
    logger.d('Getting download URL...');
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    logger.i('Image uploaded successfully: $downloadUrl');
    
    // 임시 파일 정리
    try {
      if (await compressedFile.exists()) {
        await compressedFile.delete();
        logger.d('Temporary compressed file deleted');
      }
    } catch (e) {
      logger.w('Failed to delete temporary file: $e');
    }
    
    return downloadUrl;
  } catch (e, stackTrace) {
    logger.e('Error uploading image: $e');
    logger.e('Stack trace: $stackTrace');
    
    if (e is FirebaseException) {
      logger.e('Firebase error code: ${e.code}');
      logger.e('Firebase error message: ${e.message}');
    }
    
    return null;
  }
}
```

**개선사항**:
- ✅ 파일 존재 여부 확인
- ✅ 파일 크기 및 압축률 로깅
- ✅ Storage 경로 로깅
- ✅ 업로드 진행률 실시간 모니터링
- ✅ FirebaseException 상세 정보 로깅
- ✅ 임시 압축 파일 자동 삭제
- ✅ 각 단계별 상세 로깅

---

### 4. CreatePostScreen UI/UX 개선

**파일**: `lib/features/community/presentation/create_post_screen.dart`

#### 상태 관리 개선
```dart
class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  // 기존
  bool _isSubmitting = false;
  
  // 추가
  bool _isUploadingImages = false;
  int _uploadedImageCount = 0;
  final List<XFile> _selectedImages = [];
}
```

#### 이미지 업로드 진행률 표시
```dart
// 각 이미지 업로드 시 카운터 업데이트
for (int i = 0; i < files.length; i++) {
  final url = await storageService.uploadPostImage(files[i], firebaseUser.uid);
  if (url != null) {
    imageUrls.add(url);
    if (mounted) {
      setState(() {
        _uploadedImageCount = i + 1;
      });
    }
  }
}
```

#### 로딩 오버레이
```dart
// 로딩 오버레이
if (_isUploadingImages)
  Container(
    color: Colors.black87,
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
            const SizedBox(height: 24),
            Text(
              '이미지 업로드 중...',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_uploadedImageCount / ${_selectedImages.length}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
```

#### 에러 처리 강화
```dart
try {
  // ... 게시글 작성 로직 ...
  
  // 모든 이미지 업로드 실패 시
  if (imageUrls.isEmpty && files.isNotEmpty) {
    logger.e('All images failed to upload');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지 업로드에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }
  
} catch (e, stackTrace) {
  logger.e('Unexpected error during post submission: $e');
  logger.e('Stack trace: $stackTrace');
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('오류가 발생했습니다: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**개선사항**:
- ✅ 이미지 업로드 진행률 UI 표시
- ✅ 업로드 중 뒤로가기 방지
- ✅ 상세한 로깅 (각 단계별)
- ✅ 구체적인 에러 메시지
- ✅ 모든 이미지 업로드 실패 시 중단
- ✅ try-catch로 예외 처리

---

## 📊 문제 해결 흐름

### Before (실패 흐름)
```
1. 이미지 선택 ✅
2. 이미지 Storage 업로드 ✅
3. Firestore에 게시글 저장 시도
   └─> Firestore Rules: userId 필드 체크 ❌
   └─> 실제 데이터: authorId 필드 사용
   └─> 권한 거부 (Permission Denied) ❌
4. "게시글 작성에 실패했습니다" 표시
```

### After (성공 흐름)
```
1. 이미지 선택 ✅
2. 이미지 압축 (로깅: 원본/압축 크기, 비율) ✅
3. Storage 업로드 (로깅: 경로, 진행률) ✅
   └─> UI: "이미지 업로드 중... 1/3" 표시
4. PostModel 생성
   └─> id 필드 제거
   └─> authorId 필드 사용 ✅
5. Firestore 저장
   └─> Rules: authorId 체크 ✅
   └─> 권한 확인 통과 ✅
6. "게시글이 작성되었습니다" 표시 ✅
```

---

## 🧪 테스트 체크리스트

### 이미지 업로드 테스트
- [ ] 이미지 1장 업로드
- [ ] 이미지 5장(최대) 업로드
- [ ] 대용량 이미지(5MB+) 업로드
- [ ] 네트워크 끊김 시 에러 처리
- [ ] 업로드 진행률 UI 확인

### Firestore 저장 테스트
- [ ] 텍스트만 게시글 작성
- [ ] 텍스트 + 이미지 게시글 작성
- [ ] 제목/내용 유효성 검사
- [ ] 로그아웃 상태에서 작성 시도

### 에러 처리 테스트
- [ ] Storage 업로드 실패 시나리오
- [ ] Firestore 저장 실패 시나리오
- [ ] 일부 이미지만 실패하는 경우
- [ ] 모든 이미지 실패하는 경우

### UI/UX 테스트
- [ ] 로딩 상태 표시
- [ ] 업로드 중 뒤로가기 방지
- [ ] 에러 메시지 명확성
- [ ] 성공 메시지 표시

---

## 🔧 디버깅 가이드

### 로그 확인 방법

```bash
# 전체 로그
flutter logs

# 이미지 업로드 관련
flutter logs | grep "image"
flutter logs | grep "upload"

# Firestore 관련
flutter logs | grep "post"
flutter logs | grep "Creating post"

# 에러만 확인
flutter logs | grep "Error"
flutter logs | grep "Stack trace"
```

### 주요 로그 지점

1. **이미지 압축**
   - "Starting image compression"
   - "Original size: X KB"
   - "Compressed size: X KB"
   - "Compression ratio: X%"

2. **Storage 업로드**
   - "Starting image upload for user: {userId}"
   - "Image file size: X bytes"
   - "Storage path: posts/{userId}/{fileName}"
   - "Upload progress: X%"
   - "Image uploaded successfully: {url}"

3. **Firestore 저장**
   - "Creating post with title: {title}"
   - "Author ID: {authorId}"
   - "Image URLs count: X"
   - "Post data to be saved: [keys]"
   - "Post created successfully with ID: {postId}"

### Firebase Console 확인

1. **Storage 확인**
   - Firebase Console → Storage
   - `posts/{userId}/` 경로에 이미지 확인
   - 파일명은 UUID 형식

2. **Firestore 확인**
   - Firebase Console → Firestore Database
   - `posts` 컬렉션 확인
   - 필드 확인: `authorId`, `title`, `content`, `imageUrls`

3. **Rules 확인**
   - Firebase Console → Firestore Database → Rules
   - `authorId` 필드 체크 확인

---

## 🚀 배포 전 확인사항

### 1. Firestore Rules 배포
```bash
# Rules 파일 확인
cat firestore.rules

# Rules 배포 (Firebase CLI 필요)
firebase deploy --only firestore:rules
```

### 2. 앱 재빌드
```bash
# Clean build
flutter clean
flutter pub get

# iOS
flutter build ios

# Android
flutter build appbundle
```

### 3. 테스트 환경 검증
- [ ] 개발 환경에서 게시글 작성 성공
- [ ] 로그에서 "Post created successfully" 확인
- [ ] Firebase Console에서 데이터 확인
- [ ] Storage에서 이미지 확인

---

## 📝 변경 파일 요약

1. **firestore.rules** - Firestore Security Rules 수정
   - `userId` → `authorId` 변경
   - Comment 검증 함수 오타 수정

2. **lib/repositories/post_repository.dart** - 로깅 강화
   - `id` 필드 명시적 제거
   - 상세 로깅 추가

3. **lib/services/storage_service.dart** - 업로드 로직 개선
   - 파일 존재 확인
   - 압축률 로깅
   - 진행률 모니터링
   - FirebaseException 처리
   - 임시 파일 정리

4. **lib/features/community/presentation/create_post_screen.dart** - UI/UX 개선
   - 업로드 진행률 표시
   - 로딩 오버레이
   - 상세 로깅
   - 에러 처리 강화

---

## 🎯 핵심 해결 포인트

### 가장 중요한 수정
**Firestore Rules의 `userId` → `authorId` 변경**

이것이 실제 업로드 실패의 **근본 원인**이었습니다!

### 추가 개선사항
- 상세한 로깅으로 디버깅 용이
- 사용자 피드백 개선 (진행률, 명확한 에러 메시지)
- 임시 파일 정리로 저장공간 관리
- 에러 발생 시 구체적인 원인 파악 가능

---

## 💡 향후 개선 방향

1. **오프라인 지원**
   - 이미지를 로컬에 저장
   - 네트워크 복구 시 자동 업로드

2. **이미지 최적화**
   - WebP 포맷 사용
   - 썸네일 자동 생성

3. **배치 업로드**
   - 여러 이미지 동시 업로드
   - 병렬 처리로 속도 향상

4. **재시도 로직**
   - 업로드 실패 시 자동 재시도
   - Exponential backoff

5. **Storage 할당량 관리**
   - 사용자당 업로드 용량 제한
   - 오래된 이미지 자동 삭제

---

## ✅ 결론

이미지 업로드 실패의 주요 원인은 **Firestore Security Rules와 실제 데이터 모델의 필드명 불일치**였습니다.

- Firestore Rules: `userId` 체크
- 실제 PostModel: `authorId` 사용

이를 수정하고, 추가적으로 로깅, UI/UX, 에러 처리를 개선하여 안정적인 이미지 업로드 기능을 구현했습니다.
