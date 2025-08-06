# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter todo application with Firebase authentication integration. The app supports both Google and Microsoft sign-in using Firebase Auth, Google Sign-In, and Azure AD OAuth.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app in development mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web version
- `flutter build linux` - Build Linux desktop app
- `flutter build windows` - Build Windows desktop app
- `flutter build macos` - Build macOS app

### Testing and Quality
- `flutter test` - Run widget tests
- `flutter analyze` - Run static analysis and linting
- `dart fix --apply` - Auto-fix lint issues

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter pub upgrade --major-versions` - Upgrade to latest major versions
- `flutter pub outdated` - Check for outdated dependencies

### Platform-Specific Setup
- `flutter doctor` - Check Flutter installation and platform setup
- `flutter devices` - List available devices/emulators

## Architecture

### Core Structure
- **lib/main.dart**: Main application entry point containing TodoApp, AuthWrapper, LoginScreen, and TodoListScreen
- **lib/auth_service.dart**: Authentication service handling Google and Microsoft sign-in via Firebase
- **lib/firebase_options.dart**: Auto-generated Firebase configuration

### Key Components
1. **TodoApp**: Root MaterialApp with global navigator key for OAuth
2. **AuthWrapper**: Stream-based authentication state management
3. **TodoListScreen**: Main todo interface with CRUD operations
4. **AuthService**: Centralized authentication handling

### Authentication Flow
- Firebase Auth as the primary authentication provider
- Google Sign-In integration via google_sign_in package
- Microsoft Sign-In via aad_oauth package with Azure AD
- OAuth config includes tenant, clientId, scope, and redirectUri

### Data Model
- **TodoItem**: Simple in-memory model with task, dueDate, and isCompleted fields
- No persistent storage currently implemented (data resets on app restart)

## Configuration Files

### Firebase Setup
- `firebase.json`: Firebase project configuration
- `android/app/google-services.json`: Android Firebase config
- Platform-specific Firebase configurations for iOS, web, etc.

### Code Quality
- `analysis_options.yaml`: Dart analyzer configuration using flutter_lints
- Standard Flutter linting rules with package:flutter_lints/flutter.yaml

### Dependencies (pubspec.yaml)
Key packages:
- firebase_core, firebase_auth: Firebase integration
- google_sign_in: Google authentication
- aad_oauth: Microsoft Azure AD authentication
- google_fonts: Custom typography
- intl: Date/time formatting

## Important Notes

### Authentication Configuration
- Microsoft OAuth requires proper Azure AD app registration
- Client ID in main.dart should match Azure configuration
- Redirect URI must be configured in Azure: `msal56fe33c3-6a96-4dde-948b-1bcf1aa17364://auth`

### Current Limitations
- Todo items are stored in memory only (no persistence)
- Test file (test/widget_test.dart) references non-existent MyApp class and needs updating

### Platform Support
This is a multi-platform Flutter app supporting:
- Android (with Gradle/Kotlin setup)
- iOS (with Xcode project)
- Web (with manifest.json)
- Linux, Windows, macOS desktop platforms