import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get authLoginEndpoint =>
      dotenv.env['AUTH_LOGIN_ENDPOINT'] ?? '';

  static String get authRefreshTokenEndpoint =>
      dotenv.env['AUTH_REFRESH_TOKEN_ENDPOINT'] ?? '';

  static String get authLoginFirebaseEndpoint =>
      dotenv.env['AUTH_LOGIN_FIREBASE_ENDPOINT'] ?? '';

  static String get telegramBotToken =>
      dotenv.env['TELEGRAM_BOT_TOKEN'] ?? '';
      
  static String get telegramChatId =>
      dotenv.env['TELEGRAM_CHAT_ID'] ?? '';
}
