# Firebase Storage 연동 가이드

## 🎯 구현 완료 기능

### 1. Firebase Storage 서비스
- ✅ 이미지 선택 (갤러리/카메라)
- ✅ 다중 이미지 선택 (최대 5장)
- ✅ 이미지 압축 및 최적화
- ✅ Firebase Storage 업로드
- ✅ 동영상 업로드 (준비 완료)
- ✅ 프로필 사진 업로드
- ✅ 파일 삭제

### 2. 게시글 이미지 기능
- ✅ 게시글 작성 시 이미지 첨부
- ✅ 이미지 미리보기
- ✅ 이미지 삭제
- ✅ 게시글 상세에서 이미지 표시
- ✅ 이미지 갤러리 (PageView)

### 3. 댓글 관리
- ✅ 댓글 작성
- ✅ **댓글 수정** (작성자만)
- ✅ 댓글 삭제 (작성자만)
- ✅ 실시간 업데이트

## 📦 추가된 패키지

```yaml
dependencies:
  # Image Picker & Compression
  image_picker: ^1.1.2              # 이미지/동영상 선택
  flutter_image_compress: ^2.3.0    # 이미지 압축
  path_provider: ^2.1.4             # 파일 경로
  path: ^1.9.0                      # 경로 조작
  uuid: ^4.5.1                      # 고유 파일명 생성
```

## 🏗️ 파일 구조

```
lib/
├── services/
│   └── storage_service.dart        # Firebase Storage 서비스
├── providers/
│   └── storage_provider.dart       # Storage Provider
└── features/community/presentation/
    ├── create_post_screen.dart     # 이미지 업로드 추가
    ├── post_detail_screen.dart     # 이미지 표시 & 댓글 수정
    └── edit_post_screen.dart       # 게시글 수정
```

## 🔧 Storage 서비스 기능

### 이미지 선택

```dart
// 갤러리에서 단일 이미지 선택
final storageService = ref.read(storageServiceProvider);
final XFile? image = await storageService.pickImageFromGallery();

// 다중 이미지 선택 (최대 5장)
final List<XFile> images = await storageService.pickMultipleImages(maxImages: 5);

// 카메라로 촬영
final XFile? image = await storageService.pickImageFromCamera();
```

### 이미지 압축 및 업로드

```dart
// 이미지 압축
final File? compressed = await storageService.compressImage(file);

// 단일 이미지 업로드
final String? url = await storageService.uploadPostImage(file, userId);

// 다중 이미지 업로드
final List<String> urls = await storageService.uploadMultipleImages(files, userId);
```

### 파일 삭제

```dart
// 단일 파일 삭제
await storageService.deleteFile(url);

// 다중 파일 삭제
await storageService.deleteMultipleFiles(urls);
```

## 📱 사용 방법

### 게시글에 이미지 첨부

1. **게시글 작성 화면**
   - "이미지 추가" 버튼 클릭
   - 갤러리에서 이미지 선택 (최대 5장)
   - 선택한 이미지 미리보기
   - X 버튼으로 이미지 제거 가능

2. **자동 처리**
   - 이미지 자동 압축 (1080p, 85% 품질)
   - Firebase Storage 업로드
   - URL을 Firestore에 저장

3. **게시글 상세**
   - PageView로 이미지 갤러리 표시
   - 좌우 스와이프로 이미지 전환
   - 하단에 페이지 인디케이터 표시

### 댓글 수정

1. **자신의 댓글**
   - ⋮ 메뉴 클릭
   - **수정** 선택

2. **수정 모드**
   - 댓글 내용이 입력창에 로드
   - "댓글 수정 중..." 표시
   - 내용 수정 후 ✓ 버튼으로 저장
   - X 버튼으로 수정 취소

## 🗂️ Firebase Storage 구조

```
gs://your-project.appspot.com/
├── posts/
│   └── {userId}/
│       ├── {uuid}.jpg
│       ├── {uuid}.jpg
│       └── ...
├── videos/
│   └── {userId}/
│       └── {uuid}.mp4
└── profiles/
    └── {userId}/
        └── profile.jpg
```

## 🔒 보안 규칙 (Firebase Console 설정 필요)

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 게시글 이미지
    match /posts/{userId}/{fileName} {
      allow read: if true;  // 누구나 읽기 가능
      allow write: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // 동영상
    match /videos/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // 프로필 사진
    match /profiles/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## ⚙️ 이미지 최적화 설정

### 압축 설정
```dart
final result = await FlutterImageCompress.compressAndGetFile(
  file.path,
  targetPath,
  quality: 85,        // 85% 품질
  minWidth: 1080,     // 최소 너비
  minHeight: 1080,    // 최소 높이
);
```

### 업로드 설정
```dart
final metadata = SettableMetadata(
  contentType: 'image/jpeg',
  customMetadata: {
    'uploadedBy': userId,
    'uploadedAt': DateTime.now().toIso8601String(),
  },
);
```

## 🎨 UI 특징

### 이미지 미리보기
- 가로 스크롤 리스트
- 120x120 썸네일
- X 버튼으로 삭제
- 선택 개수 표시

### 이미지 갤러리
- PageView로 전체 화면 표시
- 부드러운 스와이프
- 로딩 인디케이터
- 에러 처리

### 댓글 수정 UI
- "댓글 수정 중..." 배너
- 수정/취소 버튼
- 입력창 힌트 텍스트 변경
- 전송 아이콘 → 체크 아이콘

## 🚀 향후 개선 사항

### 1. 전체 화면 이미지 뷰어
```dart
// 이미지 탭 시 전체 화면으로 확대
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullScreenImageViewer(
        images: widget.post.imageUrls,
        initialIndex: index,
      ),
    ),
  );
}
```

### 2. 동영상 재생
```dart
// video_player 패키지 사용
VideoPlayerController controller = VideoPlayerController.network(videoUrl);
await controller.initialize();
controller.play();
```

### 3. 이미지 편집
- 크롭
- 필터
- 회전
- 스티커

### 4. 업로드 진행률
```dart
uploadTask.snapshotEvents.listen((snapshot) {
  final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  ref.read(uploadProgressProvider.notifier).state = progress;
});
```

## 💡 사용 팁

### 이미지 선택
- 최대 5장까지 선택 가능
- 자동으로 압축되어 빠른 업로드
- 미리보기에서 확인 후 삭제 가능

### 댓글 수정
- 자신의 댓글만 수정 가능
- 수정 중 취소 가능
- 수정 이력은 `updatedAt`에 기록

### 성능
- 이미지 압축으로 빠른 업로드
- 네트워크 사용량 최소화
- 로딩 상태 표시로 UX 개선

## 🐛 문제 해결

### 이미지가 업로드되지 않음
1. Firebase Storage 규칙 확인
2. 로그인 상태 확인
3. 네트워크 연결 확인
4. 로그 확인 (`logger.e`)

### 이미지가 표시되지 않음
1. URL이 유효한지 확인
2. Storage 읽기 권한 확인
3. 네트워크 연결 확인

### 압축이 느림
1. 이미지 크기가 너무 큰 경우
2. 기기 성능에 따라 다름
3. 압축 품질 조정 고려

## 📊 데이터 사용량

### 이미지
- 원본: 평균 3-5MB
- 압축 후: 평균 200-500KB
- **절약률: ~90%**

### 업로드 시간
- 1장: 약 1-3초
- 5장: 약 5-15초
- (네트워크 속도에 따라 다름)

## 🔐 권한 설정

### Android (AndroidManifest.xml)
```xml
<!-- 이미 추가되어 있음 -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS (Info.plist)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>게시글에 사진을 첨부하기 위해 앨범 접근 권한이 필요합니다.</string>
<key>NSCameraUsageDescription</key>
<string>사진을 촬영하기 위해 카메라 접근 권한이 필요합니다.</string>
```

## 📚 참고 자료

- [Firebase Storage 문서](https://firebase.google.com/docs/storage)
- [image_picker 문서](https://pub.dev/packages/image_picker)
- [flutter_image_compress 문서](https://pub.dev/packages/flutter_image_compress)




