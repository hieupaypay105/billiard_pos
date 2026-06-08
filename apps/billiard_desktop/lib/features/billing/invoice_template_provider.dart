import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

/// Model đại diện cho cấu hình mẫu hóa đơn K80 lấy từ backend.
class InvoiceTemplate {
  final String storeName;
  final String alignStoreName;
  final String fontSizeStoreName;
  final bool showStoreName;
  final String? address;
  final String alignAddress;
  final String? phone;
  final String alignPhone;
  final String title;
  final String alignTitle;
  final String fontSizeTitle;
  final String? logoUrl;
  final bool showLogo;
  final String logoPosition;
  final int logoHeight;
  final int logoWidth;
  final bool showTableName;
  final bool showCashier;
  final bool showCustomer;
  final bool showCheckinCheckout;
  final bool showDuration;
  final bool showQrPayment;
  final String? qrBankName;
  final String? qrAccountNumber;
  final String? qrAccountName;
  final String? qrStaticUrl;
  final String qrType;
  final String? footerMessage;
  final String alignFooter;
  final String fontSize;
  final String lineSpacing;

  const InvoiceTemplate({
    required this.storeName,
    required this.alignStoreName,
    required this.fontSizeStoreName,
    required this.showStoreName,
    this.address,
    required this.alignAddress,
    this.phone,
    required this.alignPhone,
    required this.title,
    required this.alignTitle,
    required this.fontSizeTitle,
    this.logoUrl,
    required this.showLogo,
    required this.logoPosition,
    required this.logoHeight,
    required this.logoWidth,
    required this.showTableName,
    required this.showCashier,
    required this.showCustomer,
    required this.showCheckinCheckout,
    required this.showDuration,
    required this.showQrPayment,
    this.qrBankName,
    this.qrAccountNumber,
    this.qrAccountName,
    this.qrStaticUrl,
    required this.qrType,
    this.footerMessage,
    required this.alignFooter,
    required this.fontSize,
    required this.lineSpacing,
  });

  factory InvoiceTemplate.fromMap(Map<String, dynamic> m) {
    int parseInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    bool parseBool(dynamic v, {bool fallback = true}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is int) return v != 0;
      return v.toString() == '1' || v.toString().toLowerCase() == 'true';
    }

    return InvoiceTemplate(
      storeName: m['store_name']?.toString() ?? 'Billiard Club',
      alignStoreName: m['align_store_name']?.toString() ?? 'center',
      fontSizeStoreName: m['font_size_store_name']?.toString() ?? 'medium',
      showStoreName: parseBool(m['show_store_name']),
      address: m['address']?.toString(),
      alignAddress: m['align_address']?.toString() ?? 'center',
      phone: m['phone']?.toString(),
      alignPhone: m['align_phone']?.toString() ?? 'center',
      title: m['title']?.toString() ?? 'HÓA ĐƠN THANH TOÁN',
      alignTitle: m['align_title']?.toString() ?? 'center',
      fontSizeTitle: m['font_size_title']?.toString() ?? 'large',
      logoUrl: m['logo_url']?.toString(),
      showLogo: parseBool(m['show_logo']),
      logoPosition: m['logo_position']?.toString() ?? 'center',
      logoHeight: parseInt(m['logo_height'], 80),
      logoWidth: parseInt(m['logo_width'], 120),
      showTableName: parseBool(m['show_table_name']),
      showCashier: parseBool(m['show_cashier']),
      showCustomer: parseBool(m['show_customer']),
      showCheckinCheckout: parseBool(m['show_checkin_checkout']),
      showDuration: parseBool(m['show_duration']),
      showQrPayment: parseBool(m['show_qr_payment'], fallback: false),
      qrBankName: m['qr_bank_name']?.toString(),
      qrAccountNumber: m['qr_account_number']?.toString(),
      qrAccountName: m['qr_account_name']?.toString(),
      qrStaticUrl: m['qr_static_url']?.toString(),
      qrType: m['qr_type']?.toString() ?? 'dynamic',
      footerMessage: m['footer_message']?.toString(),
      alignFooter: m['align_footer']?.toString() ?? 'center',
      fontSize: m['font_size']?.toString() ?? 'medium',
      lineSpacing: m['line_spacing']?.toString() ?? 'medium',
    );
  }

  /// Trả về template mặc định khi chưa sync được từ backend.
  static const InvoiceTemplate defaultTemplate = InvoiceTemplate(
    storeName: 'Billiard Club',
    alignStoreName: 'center',
    fontSizeStoreName: 'medium',
    showStoreName: true,
    address: null,
    alignAddress: 'center',
    phone: null,
    alignPhone: 'center',
    title: 'HÓA ĐƠN THANH TOÁN',
    alignTitle: 'center',
    fontSizeTitle: 'large',
    logoUrl: null,
    showLogo: false,
    logoPosition: 'center',
    logoHeight: 80,
    logoWidth: 120,
    showTableName: true,
    showCashier: true,
    showCustomer: true,
    showCheckinCheckout: true,
    showDuration: true,
    showQrPayment: false,
    qrBankName: null,
    qrAccountNumber: null,
    qrAccountName: null,
    qrStaticUrl: null,
    qrType: 'dynamic',
    footerMessage: null,
    alignFooter: 'center',
    fontSize: 'medium',
    lineSpacing: 'medium',
  );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// FutureProvider đọc template từ local DB (đã được sync từ backend) hoặc fetch online.
/// Sử dụng autoDispose để tự động giải phóng và tải lại cấu hình mới nhất mỗi khi Dialog xem trước mở ra.
final invoiceTemplateProvider =
    FutureProvider.autoDispose<InvoiceTemplate>((ref) async {
  final localDb = ref.read(localDbServiceProvider);
  final api = ref.read(apiClientProvider);

  // 1. Nếu online, thử fetch online trước để luôn lấy cấu hình mới nhất từ backend
  try {
    final remote = await api.getInvoiceTemplate().timeout(const Duration(seconds: 2));
    if (remote != null) {
      await localDb.saveInvoiceTemplate(remote);
      return InvoiceTemplate.fromMap(remote);
    }
  } catch (e) {
    // Bỏ qua lỗi kết nối / timeout và chuyển sang đọc SQLite cache
  }

  // 2. Fallback đọc từ SQLite cache cục bộ
  final cached = await localDb.getInvoiceTemplate();
  if (cached != null) {
    return InvoiceTemplate.fromMap(cached);
  }

  // 3. Fallback về default khi không có cả mạng lẫn cache
  return InvoiceTemplate.defaultTemplate;
});
