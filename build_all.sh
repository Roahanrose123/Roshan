#!/bin/bash

echo "🚀 Building TODO-APP for all platforms..."
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
flutter pub get

echo ""
echo "🌐 BUILDING WEB VERSION (Website)"
echo "=================================="
print_status "Building web application..."

# Restore web configuration
cp lib/main_web.dart lib/main.dart 2>/dev/null || echo "Web main already in place"
cp pubspec_full.yaml pubspec.yaml 2>/dev/null || echo "Full pubspec already in place"
flutter pub get

if flutter build web --release; then
    print_success "Web build completed!"
    cp -r build/web builds/web
    print_status "Web files available in: builds/web/"
    print_status "To serve: python3 serve.py"
else
    print_error "Web build failed!"
fi

echo ""
echo "🐧 BUILDING LINUX DESKTOP APP"
echo "=============================="
print_status "Switching to desktop configuration..."

# Switch to desktop configuration
cp lib/main_desktop.dart lib/main.dart
cp pubspec_desktop.yaml pubspec.yaml
flutter pub get

if flutter build linux --release; then
    print_success "Linux build completed!"
    cp -r build/linux/x64/release/bundle builds/linux
    print_status "Linux executable available in: builds/linux/todo_app"
else
    print_error "Linux build failed!"
fi

echo ""
echo "🤖 BUILDING ANDROID APP"
echo "======================="
print_status "Switching back to mobile configuration..."

# Restore mobile configuration  
cp lib/main_web.dart lib/main.dart
cp pubspec_full.yaml pubspec.yaml
flutter pub get

if flutter build apk --release; then
    print_success "Android build completed!"
    cp build/app/outputs/flutter-apk/app-release.apk builds/todo_app.apk
    print_status "Android APK available in: builds/todo_app.apk"
else
    print_error "Android build failed!"
fi

echo ""
echo "💻 WINDOWS BUILD INSTRUCTIONS"
echo "============================="
print_warning "Windows builds must be done on Windows. Run this on Windows:"
echo "  1. flutter build windows --release"
echo "  2. Find executable in: build/windows/x64/runner/Release/todo_app.exe"

echo ""
echo "📱 SUMMARY"
echo "=========="
print_success "BUILD COMPLETE!"
echo ""
echo "📁 Your builds are in the 'builds/' directory:"
echo "   🌐 Web:     builds/web/ (run: python3 serve.py)"
echo "   🐧 Linux:   builds/linux/todo_app"
echo "   🤖 Android: builds/todo_app.apk"
echo "   💻 Windows: (build on Windows machine)"
echo ""
print_status "Your Flutter todo app is ready for deployment on all platforms!"