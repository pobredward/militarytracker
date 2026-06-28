#!/bin/bash

# Military Tracker App Icon Generator
# 이 스크립트는 1024x1024 PNG 파일로부터 모든 iOS/Android 앱 아이콘을 생성합니다.

echo "🎨 Military Tracker App Icon Generator"
echo "======================================"
echo ""

# 1. 이미지 파일 확인
if [ ! -f "assets/images/app_icon.png" ]; then
    echo "❌ 오류: assets/images/app_icon.png 파일을 찾을 수 없습니다."
    echo ""
    echo "📝 다음 단계를 따라주세요:"
    echo "1. 1024x1024 PNG 이미지를 준비하세요"
    echo "2. 파일을 assets/images/app_icon.png로 저장하세요"
    echo "3. 이 스크립트를 다시 실행하세요"
    exit 1
fi

echo "✅ 아이콘 파일 발견!"
echo ""

# 2. 이미지 크기 확인 (macOS의 경우)
if command -v sips &> /dev/null; then
    SIZE=$(sips -g pixelWidth -g pixelHeight assets/images/app_icon.png 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}')
    echo "📐 이미지 크기: $(echo $SIZE | tr '\n' 'x' | sed 's/x$//')"
    echo ""
fi

# 3. Flutter 아이콘 생성
echo "🚀 앱 아이콘 생성 시작..."
echo ""

flutter pub get
flutter pub run flutter_launcher_icons

if [ $? -eq 0 ]; then
    echo ""
    echo "✨ 성공! 앱 아이콘이 생성되었습니다!"
    echo ""
    echo "📱 생성된 아이콘:"
    echo "  - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
    echo "  - Android: android/app/src/main/res/mipmap-*/"
    echo ""
    echo "🎉 이제 앱을 빌드할 수 있습니다!"
    echo ""
    echo "다음 명령어로 확인:"
    echo "  iOS:     flutter build ios --release"
    echo "  Android: flutter build appbundle --release"
else
    echo ""
    echo "❌ 오류가 발생했습니다."
    echo "위의 오류 메시지를 확인해주세요."
    exit 1
fi
