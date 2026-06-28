# 프로필 화면 즉시 수정 가이드

## 1. profile_screen.dart 수정

### 1-1. 로그아웃 (라인 67)

```dart
// Before
if (confirm == true) {
  await authActions.signOut();
}

// After
if (confirm == true && context.mounted) {
  final result = await authActions.signOut();
  result.when(
    success: (_) {
      // 로그아웃 성공 (자동으로 AuthGate가 로그인 화면으로 전환)
    },
    failure: (message, _) {
      if (context.mounted) {
        AppSnackBar.showError(context, message);
      }
    },
  );
}
```

### 1-2. 계정 삭제 (라인 483-493)

```dart
// Before
if (confirm == true && context.mounted) {
  final error = await authActions.deleteAccount();
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: const Color(0xFFCF6679),
      ),
    );
  }
}

// After
if (confirm == true && context.mounted) {
  final result = await authActions.deleteAccount();
  result.when(
    success: (_) {
      // 계정 삭제 성공 (자동으로 로그아웃)
      if (context.mounted) {
        AppSnackBar.showSuccess(context, '계정이 삭제되었습니다');
      }
    },
    failure: (message, _) {
      if (context.mounted) {
        AppSnackBar.showError(context, message);
      }
    },
  );
}
```

### 1-3. Import 추가 (파일 상단)

```dart
import '../../../widgets/app_snackbar.dart';
```

---

## 2. edit_profile_screen.dart 수정

### 2-1. Import 추가 (파일 상단)

```dart
import '../../../widgets/app_snackbar.dart';
```

### 2-2. 성공 메시지 (라인 213-218)

```dart
// Before
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('프로필이 업데이트되었습니다'),
      backgroundColor: Color(0xFF00C853),
    ),
  );
  Navigator.pop(context);
}

// After
if (mounted) {
  AppSnackBar.showSuccess(context, '프로필이 업데이트되었습니다');
  Navigator.pop(context);
}
```

### 2-3. 에러 메시지 (라인 222-229)

```dart
// Before
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('프로필 업데이트 실패: $e'),
      backgroundColor: const Color(0xFFCF6679),
    ),
  );
}

// After
if (mounted) {
  AppSnackBar.showError(context, '프로필 업데이트 실패: ${e.toString()}');
}
```

---

## 3. follow_provider.dart 수정

### 3-1. Import 추가 (파일 상단)

```dart
import '../core/config/logger.dart';
```

### 3-2. print → logger 변경

```dart
// Before (라인 93-96, 99-100, 112-113, 115-116)
print('🔍 Toggle Follow - userId: $userId, currentFollowing: $isFollowing');
print('👋 Unfollowing user: $userId');
print('👍 Following user: $userId');
print('✅ Toggle Follow completed successfully');
print('❌ Toggle Follow error: $e');

// After
logger.d('Toggle Follow - userId: $userId, currentFollowing: $isFollowing');
logger.i('Unfollowing user: $userId');
logger.i('Following user: $userId');
logger.i('Toggle Follow completed successfully');
logger.e('Toggle Follow error', e, stack);
```

---

## 4. user_profile_screen.dart 수정

### 4-1. Unused import 제거 (라인 6)

```dart
// Before
import '../../community/presentation/community_screen.dart';

// After
// (삭제)
```

---

## 적용 순서

```bash
# 1. 백업
git add .
git commit -m "backup: before profile fixes"

# 2. 수정 적용
# - profile_screen.dart
# - edit_profile_screen.dart
# - follow_provider.dart
# - user_profile_screen.dart

# 3. 테스트
flutter analyze
flutter run

# 4. 커밋
git add .
git commit -m "fix: apply Result pattern and AppSnackBar to profile screens"
```

---

## 검증 체크리스트

- [ ] profile_screen.dart에서 로그아웃 시 에러 처리 확인
- [ ] profile_screen.dart에서 계정 삭제 시 Result 패턴 적용 확인
- [ ] edit_profile_screen.dart에서 성공/실패 메시지가 AppSnackBar로 표시되는지 확인
- [ ] follow_provider.dart에서 print 문이 모두 logger로 변경되었는지 확인
- [ ] user_profile_screen.dart에서 unused import 경고 제거 확인
- [ ] flutter analyze 실행 시 에러 없는지 확인

