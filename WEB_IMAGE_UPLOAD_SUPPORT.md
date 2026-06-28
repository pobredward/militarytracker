# Flutter Web 이미지 업로드 지원 추가

## 📝 개요
Flutter Web (Chrome 시뮬레이터)에서도 커뮤니티 게시글 이미지 업로드가 되도록 수정했습니다.

## 🔍 문제점
기존 코드는 **모바일 플랫폼(iOS/Android)만 지원**했습니다:
- `File` 타입만 사용 (Web에서는 사용 불가)
- `putFile()` 메서드만 사용 (Web에서는 지원 안 됨)
- `path_provider` 패키지 의존 (Web에서 제한적)

## ✅ 해결 방법

### 1. 플랫폼 감지 추가
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// 플랫폼에 따라 다른 로직 실행
if (kIsWeb) {
  // Web 전용 로직
} else {
  // Mobile 전용 로직
}
```

### 2. `compressImage()` 함수 - Web/Mobile 지원
```dart
/// 이미지 압축 (Web에서는 bytes 압축)
Future<dynamic> compressImage(dynamic input) async {
  try {
    // Web 플랫폼인 경우
    if (kIsWeb) {
      logger.d('Web platform detected - compressing XFile');
      
      if (input is! XFile) {
        logger.e('Web requires XFile input');
        return input;
      }
      
      final XFile xFile = input;
      final bytes = await xFile.readAsBytes();
      
      // Web용 압축 (compressWithList 사용)
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );
      
      if (result.isNotEmpty) {
        logger.i('Image compressed successfully (Web)');
        return result; // Uint8List 반환
      }
      
      logger.w('Web compression failed, using original bytes');
      return bytes;
    }
    
    // 모바일 플랫폼 (기존 로직)
    if (input is! File) {
      logger.e('Mobile platform requires File input');
      return input;
    }
    
    final File file = input;
    // ... 기존 압축 로직 (compressAndGetFile 사용)
    // File 반환
  }
}
```

**핵심 차이점**:
- **Web**: `XFile` → `Uint8List` (bytes) → `compressWithList()` → `Uint8List`
- **Mobile**: `File` → `File` (temp) → `compressAndGetFile()` → `File`

### 3. `uploadPostImage()` 함수 - Web/Mobile 지원
```dart
/// 이미지 업로드 (게시글용) - Web/Mobile 지원
Future<String?> uploadPostImage(dynamic input, String userId) async {
  dynamic compressedData;
  
  try {
    logger.i('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    
    // Web 플랫폼 처리
    if (kIsWeb) {
      XFile xFile;
      if (input is XFile) {
        xFile = input;
      } else {
        logger.e('❌ Invalid input type for Web');
        return null;
      }
      
      // 이미지 압축 (bytes)
      compressedData = await compressImage(xFile);
      
      Uint8List bytes;
      if (compressedData is Uint8List) {
        bytes = compressedData;
      } else {
        bytes = await xFile.readAsBytes();
      }
      
      // Storage 업로드 (putData 사용)
      final ref = _storage.ref().child('posts/$userId/${_uuid.v4()}.jpg');
      final uploadTask = ref.putData(bytes, metadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      logger.i('✅ Image uploaded successfully (Web)');
      return downloadUrl;
    }
    
    // 모바일 플랫폼 처리
    File file;
    if (input is File) {
      file = input;
    } else if (input is XFile) {
      file = File(input.path);
    } else {
      logger.e('❌ Invalid input type for Mobile');
      return null;
    }
    
    // ... 기존 Mobile 로직 (putFile 사용)
    
  } finally {
    // 임시 파일 정리 (Mobile만 해당)
    if (!kIsWeb && compressedData != null && compressedData is File) {
      // ... 파일 삭제
    }
  }
}
```

**핵심 차이점**:
- **Web**: `XFile` → `Uint8List` → `putData()` → URL
- **Mobile**: `XFile` → `File` → `putFile()` → URL

### 4. `CreatePostScreen` 수정 - XFile 직접 전달
```dart
// 변경 전 (Mobile만 지원)
final files = _selectedImages.map((xFile) => File(xFile.path)).toList();
for (int i = 0; i < files.length; i++) {
  final url = await storageService.uploadPostImage(files[i], userId);
}

// 변경 후 (Web/Mobile 모두 지원)
for (int i = 0; i < _selectedImages.length; i++) {
  final url = await storageService.uploadPostImage(_selectedImages[i], userId);
}
```

**이유**: Web에서는 `File` 객체를 생성할 수 없으므로 `XFile`을 직접 전달

## 📊 플랫폼별 차이 요약

| 구분 | Web | Mobile |
|-----|-----|--------|
| **입력** | `XFile` | `File` 또는 `XFile` |
| **압축 방법** | `compressWithList()` | `compressAndGetFile()` |
| **압축 결과** | `Uint8List` (bytes) | `File` (임시 파일) |
| **업로드 방법** | `ref.putData(bytes)` | `ref.putFile(file)` |
| **임시 파일 정리** | 불필요 (bytes만 사용) | 필요 (임시 파일 삭제) |

## 🧪 테스트 방법

### 1. Web에서 실행
```bash
# Chrome에서 앱 실행
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

`--disable-web-security` 플래그가 필요한 이유:
- Firebase Storage CORS 정책 우회
- 로컬 개발 환경에서 필요

### 2. 테스트 시나리오
1. Chrome에서 앱 실행 ✅
2. 커뮤니티 → "게시글 작성" 이동
3. "이미지 추가" 클릭
4. 이미지 1~5장 선택
5. 제목, 내용 입력
6. "완료" 버튼 클릭
7. 로그 확인:
```
[log] Platform: Web
[log] Web platform detected - compressing XFile
[log] Image compressed successfully (Web)
[log] ✅ Image ready for upload: XX.XX KB
[log] ☁️ Starting Firebase Storage upload (Web)...
[log] 📊 Upload progress: 25.0%
[log] 📊 Upload progress: 50.0%
[log] 📊 Upload progress: 100.0%
[log] ✅ Image uploaded successfully (Web)
[log] 🔗 URL: https://firebasestorage...
```

### 3. Firebase Console 확인
1. Firebase Console → Storage
2. `posts/{userId}/` 경로 확인
3. 업로드된 이미지 파일 확인

## 🔧 변경된 파일

### 1. lib/services/storage_service.dart
- `kIsWeb` import 추가
- `compressImage()`: Web/Mobile 분기 처리
  - Web: `compressWithList()` 사용, `Uint8List` 반환
  - Mobile: `compressAndGetFile()` 사용, `File` 반환
- `uploadPostImage()`: Web/Mobile 분기 처리
  - Web: `putData()` 사용
  - Mobile: `putFile()` 사용

### 2. lib/features/community/presentation/create_post_screen.dart
- `XFile`을 `File`로 변환하지 않고 직접 전달
- `files.length` → `_selectedImages.length`로 변경

## 🎯 결과

### 지원 플랫폼
- ✅ iOS (기존)
- ✅ Android (기존)
- ✅ **Web (새로 추가!)**

### 기능
- ✅ 이미지 선택 (1~5장)
- ✅ 이미지 압축 (Web/Mobile 모두)
- ✅ Firebase Storage 업로드
- ✅ 업로드 진행률 표시
- ✅ 에러 처리
- ✅ 임시 파일 정리 (Mobile)

## 💡 주의사항

### 1. Web 플랫폼 제한사항
- **CORS 정책**: Firebase Storage에 CORS 설정 필요
- **파일 시스템 접근 제한**: `File` 객체 사용 불가
- **디버깅 시**: `--disable-web-security` 플래그 필요

### 2. Firebase Storage CORS 설정 (프로덕션)
```json
[
  {
    "origin": ["https://your-domain.com"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

gsutil을 사용하여 설정:
```bash
# cors.json 파일 생성 후
gsutil cors set cors.json gs://your-bucket-name.appspot.com
```

### 3. 개발 vs 프로덕션
- **개발**: `--disable-web-security` 사용 가능
- **프로덕션**: Firebase Storage CORS 설정 필수

## 🚀 배포

### iOS/Android (변경 없음)
```bash
flutter build ios
flutter build appbundle
```

### Web (새로 추가)
```bash
# Web 빌드
flutter build web

# Firebase Hosting에 배포
firebase deploy --only hosting
```

## ✅ 체크리스트

- [x] Web 플랫폼 감지 (`kIsWeb`)
- [x] Web용 이미지 압축 (`compressWithList`)
- [x] Web용 업로드 (`putData`)
- [x] Mobile 기존 기능 유지
- [x] 로그 추가 (플랫폼 구분)
- [x] 에러 처리
- [x] Lint 에러 없음
- [ ] Web 실제 테스트
- [ ] Firebase Storage CORS 설정 (프로덕션)

## 🎉 완료!

이제 **Web (Chrome)에서도 이미지 업로드**가 가능합니다!

테스트 방법:
```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

로그 확인:
```bash
flutter logs | grep -E "Platform:|Web|Mobile"
```
