class AppConfig {
  // Microsoft Azure AD Configuration
  static const String microsoftTenant = "common";
  static const String microsoftClientId = "56fe33c3-6a96-4dde-948b-1bcf1aa17364";
  static const String microsoftScope = "openid profile offline_access user.read";
  static const String microsoftRedirectUri = "msal56fe33c3-6a96-4dde-948b-1bcf1aa17364://auth";
  
  // App Configuration
  static const String appName = "TODO-APP";
  
  // Note: In production, these values should be loaded from environment variables
  // or a secure configuration service, not hardcoded in the source code.
  // Consider using flutter_dotenv for environment-based configuration.
}