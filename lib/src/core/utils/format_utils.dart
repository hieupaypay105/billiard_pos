import 'package:intl/intl.dart';

/// Utility class for formatting numbers, prices, etc.
sealed class FormatUtils {
  /// Định dạng số/giá tiền có bao gồm phần thập phân nếu có.
  /// Ví dụ:
  /// - 123 -> "123"
  /// - 123.45 -> "123.45"
  /// - 1234567.89 -> "1,234,567.89"
  static String formatPrice(num? price) {
    if (price == null) return '0';

    // Sử dụng NumberFormat với pattern '#,##0.##'
    // - '#' ở phần thập phân giúp loại bỏ các số 0 thừa ở cuối.
    // - Nếu là số nguyên, nó sẽ tự động ẩn phần thập phân.
    final formatter = NumberFormat('#,##0.##', 'en_US');
    return formatter.format(price);
  }

  /// Định dạng từ đầu vào là String
  static String formatPriceString(String? priceString) {
    if (priceString == null || priceString.trim().isEmpty) return '0';
    final price = num.tryParse(priceString.trim());
    if (price == null) return priceString;
    return formatPrice(price);
  }
}
