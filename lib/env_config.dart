import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get googleClientIdWeb => dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';
  static String get googleClientIdDesktop => dotenv.env['GOOGLE_CLIENT_ID_DESKTOP'] ?? '';
  static String get googleClientIdMobile => dotenv.env['GOOGLE_CLIENT_ID_MOBILE'] ?? '';
  static String get googleClientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  
  static String get microsoftClientId => dotenv.env['MICROSOFT_CLIENT_ID'] ?? '';
  static String get microsoftClientSecret => dotenv.env['MICROSOFT_CLIENT_SECRET'] ?? '';
  static String get microsoftClientIdAzure => dotenv.env['MICROSOFT_CLIENT_ID_AZURE'] ?? '';
  
  /// Initialize environment configuration
  /// Call this before using any environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
}