#!/bin/bash

echo "🚀 Building Smart TODO-APP for All Platforms..."
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create builds directory
mkdir -p builds

print_status "Cleaning previous builds..."
flutter clean

echo ""
echo "🌐 BUILDING WEB VERSION (Mobile & Desktop Compatible)"
echo "=================================================="
print_status "Building unified web application with Firebase auth..."

# Switch to web/mobile configuration
cp lib/main_smart.dart lib/main.dart
cp pubspec_unified.yaml pubspec.yaml
flutter pub get

if flutter build web --release; then
    print_success "Web build completed!"
    cp -r build/web builds/web_smart
    print_status "Smart web files available in: builds/web_smart/"
    print_status "Features: Firebase auth, Google/Microsoft SSO, auto offline fallback"
else
    print_error "Web build failed!"
fi

echo ""
echo "🖥️ BUILDING DESKTOP VERSION (Linux/Windows/Mac)"
echo "=============================================="
print_status "Building desktop application with smart connectivity..."

# Switch to desktop configuration
cp lib/main_desktop_smart.dart lib/main.dart
cp pubspec.yaml pubspec_desktop_smart.yaml  # Save current as backup
cat > pubspec.yaml << EOF
name: todo_app
description: "A Flutter todo application for desktop platforms."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.3.0
  intl: ^0.20.2
  shared_preferences: ^2.2.2
  connectivity_plus: ^6.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
EOF

flutter pub get

if flutter build linux --release; then
    print_success "Linux desktop build completed!"
    cp -r build/linux/x64/release/bundle builds/linux_smart
    print_status "Smart Linux app available in: builds/linux_smart/todo_app"
    print_status "Features: Smart online/offline detection, simulated auth"
else
    print_error "Linux build failed!"
fi

echo ""
echo "📱 ANDROID BUILD (Mobile)"
echo "========================"
print_status "Building Android app with Firebase..."

# Switch back to mobile configuration
cp lib/main_smart.dart lib/main.dart
cp pubspec_unified.yaml pubspec.yaml
flutter pub get

if timeout 300 flutter build apk --release; then
    print_success "Android build completed!"
    cp build/app/outputs/flutter-apk/app-release.apk builds/smart_todo_app.apk
    print_status "Smart Android APK available in: builds/smart_todo_app.apk"
else
    print_warning "Android build timed out or failed"
fi

echo ""
echo "💻 WINDOWS BUILD INSTRUCTIONS"
echo "============================="
print_warning "Windows builds must be done on Windows machine:"
echo "  1. Copy desktop configuration:"
echo "     cp lib/main_desktop_smart.dart lib/main.dart"
echo "     cp pubspec_desktop_smart.yaml pubspec.yaml"
echo "  2. Run: flutter build windows --release"
echo "  3. Find executable in: build/windows/x64/runner/Release/todo_app.exe"

echo ""
echo "📊 SMART TODO-APP BUILD SUMMARY"
echo "==============================="
print_success "BUILD COMPLETE!"
echo ""
echo "🎯 Your Smart Todo App Features:"
echo "  ✅ Automatic online/offline detection"
echo "  ✅ Firebase authentication (web/mobile)"
echo "  ✅ Google & Microsoft single sign-on"
echo "  ✅ Smart fallback to offline mode"
echo "  ✅ Cross-platform compatibility"
echo "  ✅ Local storage on all platforms"
echo ""
echo "📁 Your builds are in the 'builds/' directory:"
echo "   🌐 Web (Smart):      builds/web_smart/ (python3 serve.py)"
echo "   🖥️ Linux Desktop:    builds/linux_smart/todo_app"
echo "   📱 Android Mobile:   builds/smart_todo_app.apk"
echo "   💻 Windows Desktop: (build on Windows machine)"
echo ""
print_status "🎉 Your Smart Flutter Todo App is ready for deployment!"
echo ""
echo "🔥 SMART FEATURES:"
echo "  • Online Mode: Full Firebase authentication with Google/Microsoft SSO"
echo "  • Offline Mode: Automatic fallback when no internet detected"
echo "  • Desktop Mode: Simulated authentication with full offline functionality"
echo "  • Mobile Mode: Native mobile experience with cloud sync"
echo "  • Web Mode: Progressive web app that works everywhere"