# App Icon Setup Guide

## 📱 앱 아이콘 설정 가이드

### ✅ 현재 상태
- flutter_launcher_icons 패키지 설치됨
- pubspec.yaml 설정 완료
- 자동 생성 스크립트 준비 완료

### 🎨 사용할 이미지
- **크기**: 1024x1024 픽셀
- **포맷**: PNG (투명 배경 가능)
- **위치**: `assets/images/app_icon.png`

제공하신 멋진 네온 그린 "M" 로고를 사용합니다! 💚

---

## 🚀 아이콘 생성 방법

### 방법 1: 자동 스크립트 사용 (권장 ✅)

```bash
# 1. 이미지를 올바른 위치에 저장했는지 확인
# assets/images/app_icon.png

# 2. 스크립트 실행
./generate_icons.sh
```

### 방법 2: 수동 명령어

```bash
# 1. 패키지 설치 확인
flutter pub get

# 2. 아이콘 생성
flutter pub run flutter_launcher_icons
```

---

## 📋 생성되는 아이콘 목록

### iOS (15개 파일)
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png       (20x20)   - iPad Notifications
├── Icon-App-20x20@2x.png       (40x40)   - iPhone Notifications
├── Icon-App-20x20@3x.png       (60x60)   - iPhone Notifications
├── Icon-App-29x29@1x.png       (29x29)   - iPad Settings
├── Icon-App-29x29@2x.png       (58x58)   - iPhone Settings
├── Icon-App-29x29@3x.png       (87x87)   - iPhone Settings
├── Icon-App-40x40@1x.png       (40x40)   - iPad Spotlight
├── Icon-App-40x40@2x.png       (80x80)   - iPhone Spotlight
├── Icon-App-40x40@3x.png       (120x120) - iPhone Spotlight
├── Icon-App-60x60@2x.png       (120x120) - iPhone App
├── Icon-App-60x60@3x.png       (180x180) - iPhone App
├── Icon-App-76x76@1x.png       (76x76)   - iPad App
├── Icon-App-76x76@2x.png       (152x152) - iPad App
├── Icon-App-83.5x83.5@2x.png   (167x167) - iPad Pro App
└── Icon-App-1024x1024@1x.png   (1024x1024) - App Store
```

### Android (5개 크기)
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png       (48x48)
├── mipmap-hdpi/ic_launcher.png       (72x72)
├── mipmap-xhdpi/ic_launcher.png      (96x96)
├── mipmap-xxhdpi/ic_launcher.png     (144x144)
└── mipmap-xxxhdpi/ic_launcher.png    (192x192)
```

### Android Adaptive (추가)
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher_foreground.png
├── mipmap-hdpi/ic_launcher_foreground.png
├── mipmap-xhdpi/ic_launcher_foreground.png
├── mipmap-xxhdpi/ic_launcher_foreground.png
└── mipmap-xxxhdpi/ic_launcher_foreground.png
```

---

## ✅ 확인 방법

### 1. iOS 아이콘 확인
```bash
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

### 2. Android 아이콘 확인
```bash
ls -la android/app/src/main/res/mipmap-*/ic_launcher.png
```

### 3. 실제 디바이스에서 확인
```bash
# iOS
flutter run -d <ios-device>

# Android
flutter run -d <android-device>
```

---

## 🎯 pubspec.yaml 설정 (이미 완료)

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 21
  
  # iOS specific
  ios_content_json: true
  remove_alpha_ios: true
  
  # Android specific
  adaptive_icon_background: "#1A1A1A"  # 다크 배경
  adaptive_icon_foreground: "assets/images/app_icon.png"
```

---

## 🔧 문제 해결

### 문제 1: "이미지를 찾을 수 없습니다"
```bash
# 해결: 이미지 파일 위치 확인
ls -la assets/images/app_icon.png
```

### 문제 2: "투명도 경고 (iOS)"
iOS는 투명 배경을 지원하지 않습니다. 
`remove_alpha_ios: true` 설정으로 자동 처리됩니다.

### 문제 3: "빌드 오류"
```bash
# 캐시 정리
flutter clean
flutter pub get
./generate_icons.sh
```

---

## 📸 결과 미리보기

생성 후 다음과 같은 아이콘들이 생성됩니다:
- ✅ App Store 제출용 1024x1024
- ✅ iPhone 홈 화면용 (120x120, 180x180)
- ✅ iPad 홈 화면용 (76x76, 152x152)
- ✅ Spotlight 검색용 (80x80, 120x120)
- ✅ 설정 앱용 (58x58, 87x87)
- ✅ 알림용 (40x40, 60x60)

---

## 🎉 완료!

아이콘 생성이 완료되면:
1. ✅ Xcode에서 자동으로 인식됨
2. ✅ Android Studio에서 자동으로 인식됨
3. ✅ App Store/Play Store 제출 준비 완료

**다음 단계**: 앱 빌드 및 배포! 🚀
