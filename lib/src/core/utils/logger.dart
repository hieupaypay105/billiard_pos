import 'package:logger/logger.dart';

/// Global logger instance để dùng ở bất kì đâu trong app
///
/// Import file này và sử dụng trực tiếp biến `logger`.
/// Ví dụ:
/// ```dart
/// logger.d('Debug message');
/// logger.e('Error message', error: e);
/// ```
final logger = Logger(
  printer: PrettyPrinter(),
);
