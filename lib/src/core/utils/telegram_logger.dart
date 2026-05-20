import 'package:anholding_app/src/core/constants/env.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:dio/dio.dart';

class TelegramLogger {
  TelegramLogger._();

  static final Dio _dio = Dio();

  /// Gửi thông báo log đến Telegram qua bot.
  static Future<void> logToChannel(String message) async {
    final token = Env.telegramBotToken;
    final chatId = Env.telegramChatId;

    if (token.isEmpty || chatId.isEmpty) {
      logger.d('Telegram Token or Chat ID is empty! Skipping telegram log.');
      return;
    }

    final url = 'https://api.telegram.org/bot$token/sendMessage';

    final timestamp = DateTime.now().toString().split('.').first;
    final messageWithTime = '🕒 <b>Time:</b> $timestamp\n$message';

    try {
      await _dio.post(
        url,
        data: {
          'chat_id': chatId,
          'text': messageWithTime,
          'parse_mode': 'HTML',
        },
      );
      logger.d('Sent log to Telegram successfully.');
    } on DioException catch (e) {
      logger.e(
        'Failed to send log to Telegram. Response: ${e.response?.data}',
        error: e,
      );
    } catch (e) {
      logger.e('Failed to send log to Telegram', error: e);
    }
  }
}
