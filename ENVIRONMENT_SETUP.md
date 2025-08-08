# Environment Variables Setup

## Overview
This project now uses environment variables to securely manage API keys and client secrets. All sensitive information has been moved out of the source code.

## Setup Instructions

### 1. Copy Environment Template
```bash
cp .env.example .env
```

### 2. Fill in Your Actual Values
Edit the `.env` file and replace the placeholder values with your actual OAuth credentials:

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID_WEB=your_actual_google_client_id_for_web
GOOGLE_CLIENT_ID_DESKTOP=your_actual_google_client_id_for_desktop
GOOGLE_CLIENT_ID_MOBILE=your_actual_google_client_id_for_mobile
GOOGLE_CLIENT_SECRET=your_actual_google_client_secret

# Microsoft OAuth Configuration
MICROSOFT_CLIENT_ID=your_actual_microsoft_client_id
MICROSOFT_CLIENT_SECRET=your_actual_microsoft_client_secret
MICROSOFT_CLIENT_ID_AZURE=your_actual_azure_client_id
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Update Web Configuration (if using web)
In `web/index.html`, replace `YOUR_GOOGLE_WEB_CLIENT_ID` with your actual Google Web Client ID.

## Important Security Notes

⚠️ **NEVER commit the `.env` file to version control!**

- The `.env` file is already added to `.gitignore`
- Always use `.env.example` as a template for new developers
- Keep your production secrets separate from development secrets
- Rotate your secrets regularly

## Fallback Behavior
If environment variables are not found, the app will:
1. Show a warning in debug mode
2. Fall back to placeholder values (which likely won't work)
3. Continue running to prevent crashes

## Files Modified

### New Files
- `.env` - Your actual environment variables (DO NOT COMMIT)
- `.env.example` - Template for environment variables
- `lib/env_config.dart` - Environment configuration class
- `ENVIRONMENT_SETUP.md` - This setup guide

### Modified Files
- `pubspec.yaml` - Added `flutter_dotenv` dependency and `.env` asset
- `lib/main.dart` - Added environment initialization
- `lib/google_auth_service.dart` - Updated to use environment variables
- `web/index.html` - Removed hardcoded client ID
- `.gitignore` - Added comprehensive environment file exclusions

## Troubleshooting

### Environment not loading
```dart
⚠️ Warning: Environment configuration failed to load
```
- Make sure `.env` file exists in the project root
- Check that `.env` is included in `pubspec.yaml` under assets
- Verify the file format (no spaces around equals signs)

### Authentication still failing
- Verify your client IDs match your OAuth provider configuration
- Check that redirect URIs are properly configured
- Ensure you're using the correct client ID for each platform (web/mobile/desktop)

## Getting OAuth Credentials

### Google OAuth Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable Google+ API and Google Sign-In API
4. Go to Credentials → Create Credentials → OAuth 2.0 Client IDs
5. Create separate client IDs for Web, Android, iOS, and Desktop applications

### Microsoft OAuth Setup
1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to Azure Active Directory → App registrations
3. Create a new registration
4. Configure redirect URIs for your platforms
5. Generate client secrets in Certificates & secrets