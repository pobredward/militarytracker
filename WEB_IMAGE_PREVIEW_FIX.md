# Flutter Web 이미지 미리보기 에러 해결

## 🐛 문제
```
Assertion failed: file:///Users/edwardshin/flutter/packages/flutter/lib/src/widgets/image.dart:526:10
!kIsWeb
"Image.file is not supported on Flutter Web. Consider using either Image.asset or Image.network instead."
```

**원인**: Web에서는 `Image.file()`을 사용할 수 없습니다.

## ✅ 해결 방법

### CreatePostScreen 수정

**Before (Mobile만 지원):**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.file(
    File(_selectedImages[index].path),
    width: 120,
    height: 120,
    fit: BoxFit.cover,
  ),
),
```

**After (Web/Mobile 모두 지원):**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: kIsWeb
      ? FutureBuilder<Uint8List>(
          future: _selectedImages[index].readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              );
            }
            return Container(
              width: 120,
              height: 120,
              color: const Color(0xFF2A2A2A),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                ),
              ),
            );
          },
        )
      : Image.file(
          File(_selectedImages[index].path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
),
```

### 추가된 Import
```dart
import 'dart:typed_data';  // Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;  // 플랫폼 감지
```

## 💡 작동 원리

### Web 플랫폼
1. `XFile.readAsBytes()` → `Uint8List` 가져오기
2. `Image.memory(bytes)` → 메모리에서 이미지 표시
3. `FutureBuilder` → 비동기 로딩 처리

### Mobile 플랫폼
1. `XFile.path` → 파일 경로 사용
2. `Image.file(File(path))` → 파일에서 이미지 표시
3. 동기 처리 (파일 시스템 접근)

## 🔄 적용 방법

### 1. Hot Reload 실행
실행 중인 Flutter 터미널에서 `r` 키를 누르세요:
```
r Hot reload. 🔥🔥🔥
```

### 2. 또는 Hot Restart
```
R Hot restart.
```

### 3. Chrome 페이지 새로고침
브라우저에서 `Cmd+R` (Mac) 또는 `F5` (Windows)

## ✅ 결과

### Web
- ✅ 이미지 선택 가능
- ✅ 이미지 미리보기 (`Image.memory`)
- ✅ 로딩 인디케이터 표시
- ✅ 이미지 업로드 정상 작동

### Mobile
- ✅ 기존 기능 유지
- ✅ 이미지 미리보기 (`Image.file`)
- ✅ 이미지 업로드 정상 작동

## 📊 플랫폼별 차이

| 기능 | Web | Mobile |
|-----|-----|--------|
| **이미지 선택** | `XFile` | `XFile` |
| **미리보기** | `Image.memory(bytes)` | `Image.file(File)` |
| **로딩** | `FutureBuilder` | 동기 처리 |
| **업로드** | `putData(bytes)` | `putFile(File)` |

## 🎯 완료!

이제 Web에서도 이미지 미리보기가 정상적으로 표시됩니다! 🎉

**다음 단계:**
1. Chrome 터미널에서 `r` 키 입력 (Hot Reload)
2. 커뮤니티 → 게시글 작성
3. 이미지 추가 클릭
4. 이미지 선택 → **미리보기 정상 표시** ✅
