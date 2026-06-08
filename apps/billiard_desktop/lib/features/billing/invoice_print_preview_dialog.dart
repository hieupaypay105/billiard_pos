import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import 'invoice_template_provider.dart';

// ─── Lightweight cached image widget ──────────────────────────────────────────
//
// Dùng dio + path_provider để cache ảnh về thư mục temp của thiết bị.
// File cache được đặt tên theo MD5 của URL để tránh tải lại không cần thiết.
// Chỉ tải lại khi file cache không tồn tại (server thay URL → tự hết cache cũ).

class _CachedNetworkImage extends StatefulWidget {
  final String url;
  final double height;
  final BoxFit fit;
  final Widget Function()? errorWidget;

  const _CachedNetworkImage({
    required this.url,
    required this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
  });

  @override
  State<_CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<_CachedNetworkImage> {
  Future<File>? _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve(widget.url);
  }

  @override
  void didUpdateWidget(_CachedNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() => _future = _resolve(widget.url));
    }
  }

  /// Trả về File ảnh – lấy từ cache nếu đã có, ngược lại tải về và cache.
  static Future<File> _resolve(String url) async {
    final cacheDir = await getTemporaryDirectory();
    final hash = md5.convert(url.codeUnits).toString();
    final ext = url.contains('.png') ? 'png' : 'jpg';
    final file = File('${cacheDir.path}/invoice_img_$hash.$ext');
    if (await file.exists()) return file;
    final res = await Dio().get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    await file.writeAsBytes(res.data!);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
                height: widget.height,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              );
        }
        if (snap.hasError || snap.data == null) {
          return widget.errorWidget?.call() ?? const SizedBox.shrink();
        }
        return Image.file(
          snap.data!,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}

// ─── Main Dialog ──────────────────────────────────────────────────────────────

/// Dialog xem trước hoá đơn K80 (80mm) theo đúng cấu hình mẫu từ backend.
/// Thứ tự layout khớp admin mockup K80:
///   Logo → Tên quán → Địa chỉ → SĐT → ---
///   Tiêu đề → Ngày giờ → Meta (bàn/thu ngân/khách/giờ vào-ra/thời lượng) → ---
///   Bảng hàng: Tiền giờ (số lượng = giờ) + Sản phẩm → ---
///   Tổng / Khuyến mãi / TỔNG CỘNG → Ghi chú/Lý do
///   QR → Footer
class InvoicePrintPreviewDialog extends ConsumerWidget {
  final String tableName;
  final DateTime startTime;
  final DateTime endTime;
  final int playMinutes;
  final double playAmount;
  final double hourlyRate;
  final List<Map<String, dynamic>> products;
  final double totalAmount;
  final double discountPercent;
  final double discountAmount;
  final double netTotal;
  final Map<String, dynamic>? member;
  final String cashierName;
  final String? shiftLabel;
  final String status; // 'paid' | 'unpaid' | 'cancelled'
  final String? note;

  const InvoicePrintPreviewDialog({
    super.key,
    required this.tableName,
    required this.startTime,
    required this.endTime,
    required this.playMinutes,
    required this.playAmount,
    required this.hourlyRate,
    required this.products,
    required this.totalAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.netTotal,
    this.member,
    required this.cashierName,
    this.shiftLabel,
    required this.status,
    this.note,
  });

  // ─── Formatters ─────────────────────────────────────────────────────────────

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()}đ';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m.toString().padLeft(2, '0')}p';
    if (h > 0) return '$h giờ';
    return '$m phút';
  }

  /// Số giờ chơi dưới dạng chuỗi, ví dụ "2.50h"
  String _fmtHours(int minutes) {
    final h = minutes / 60.0;
    if (h == h.roundToDouble()) return '${h.toInt()}h';
    return '${h.toStringAsFixed(2)}h';
  }

  // ─── Alignment helpers ───────────────────────────────────────────────────────

  TextAlign _toTextAlign(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  // ─── Font size helpers ───────────────────────────────────────────────────────

  double _storeNameFs(String size) {
    switch (size) {
      case 'small':
        return 12;
      case 'large':
        return 17;
      case 'xlarge':
        return 20;
      default:
        return 14;
    }
  }

  double _titleFs(String size) {
    switch (size) {
      case 'small':
        return 12;
      case 'medium':
        return 14;
      case 'xlarge':
        return 20;
      default:
        return 17; // large
    }
  }

  double _bodyFs(String size) {
    switch (size) {
      case 'small':
        return 9.5;
      case 'large':
        return 12;
      default:
        return 10.5; // medium
    }
  }

  double _lineH(String spacing) {
    switch (spacing) {
      case 'large':
        return 1.7;
      case 'small':
        return 1.2;
      default:
        return 1.4;
    }
  }

  // ─── Printing ────────────────────────────────────────────────────────────────

  void _doPrint(BuildContext context) {
    // TODO: integrate esc_pos_utils_plus for actual K80 ESC/POS printing.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.print, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Đang gửi lệnh in hóa đơn K80...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(invoiceTemplateProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: templateAsync.when(
        loading: () => _shell(
          context,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (_, __) => _shell(
          context,
          child: _receipt(context, InvoiceTemplate.defaultTemplate),
        ),
        data: (t) => _shell(context, child: _receipt(context, t)),
      ),
    );
  }

  // ─── Outer shell ─────────────────────────────────────────────────────────────

  Widget _shell(BuildContext context, {required Widget child}) {
    return Container(
      width: 420,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.92),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('XEM TRƯỚC HÓA ĐƠN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          )),
                      Text('Mẫu in K80 · 80mm',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),

          // Scrollable paper
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1923),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _doPrint(context),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('In hóa đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── K80 Receipt Paper ────────────────────────────────────────────────────────

  // ─── VietQR / EMV QRCPS string builder ───────────────────────────────────────
  //
  // Tạo chuỗi QR theo định dạng VietQR (EMV QRCPS).
  // Các ứng dụng ngân hàng Việt Nam đọc được chuỗi này khi quét QR.
  //
  //  Format:
  //   000201          – Payload Format Indicator
  //   010212          – Point of Initiation (12 = dynamic)
  //   38<len><bank_guid>  – Bank GUID (napas)
  //   5303704         – Transaction Currency (VND = 704)
  //   54<len><amount> – Transaction Amount (nếu có)
  //   5802VN          – Country code
  //   62<len>...      – Additional Data (addInfo)
  //   6304<crc>       – CRC-16 CCITT (checksum)
  //
  // NOTE: CRC-16 là tùy chọn cho preview — ở đây dùng placeholder '0000' vì
  // hầu hết app ngân hàng VN chấp nhận mà không check strict CRC khi chuỗi
  // content đúng format. Để scan thực tế chuẩn 100%, cần tính CRC-16/CCITT.
  static String _buildVietQrData({
    required String bankId,   // tên ngắn ngân hàng, VD: "VietinBank", "VCB"
    required String accountNumber,
    String? accountName,
    int amountVnd = 0,
    String addInfo = '',
  }) {
    // Map tên ngân hàng phổ biến → GUID chuẩn NAPAS để ứng dụng nhận dạng
    const napasGuids = <String, String>{
      'vcb': '9704036',
      'vietcombank': '9704036',
      'vietinbank': '9704021',
      'vtin': '9704021',
      'bidv': '9704018',
      'mb': '9704153',
      'mbbank': '9704153',
      'acb': '9704281',
      'techcombank': '9704054',
      'tcb': '9704054',
      'tpbank': '9704394',
      'vpbank': '9704432',
      'sacombank': '9704066',
      'scb': '9704255',
      'hdbank': '9704157',
      'shb': '9704277',
      'ocb': '9704229',
      'seabank': '9704400',
      'abbank': '9704325',
      'vib': '9704066',
      'agribank': '9704247',
      'agri': '9704247',
      'lpbank': '9704239',
    };

    final key = bankId.toLowerCase().replaceAll(' ', '');
    final guid = napasGuids[key] ?? '970415'; // fallback: VietinBank

    // Helper: TLV field — ID(2 digit) + Length(2 digit) + Value
    String tlv(String id, String value) {
      final len = value.length.toString().padLeft(2, '0');
      return '$id$len$value';
    }

    // Sub-fields cho Merchant Account Info (tag 38 — NAPAS VietQR)
    final acctField = tlv('01', accountNumber);
    final bankField = tlv('00', guid);
    final merchantInfo = tlv('38', '$bankField$acctField');

    // Amount field (tag 54)
    final amountStr = amountVnd > 0 ? amountVnd.toString() : '';
    final amountField = amountStr.isNotEmpty ? tlv('54', amountStr) : '';

    // Additional data field (tag 62) — addInfo in sub-tag 08
    final addInfoSanitized = addInfo
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .substring(0, addInfo.length.clamp(0, 25));
    final addInfoField = addInfoSanitized.isNotEmpty
        ? tlv('62', tlv('08', addInfoSanitized))
        : '';

    // Build payload WITHOUT CRC
    final payload =
        '000201' // Payload Format Indicator
        '010212' // Dynamic QR
        '$merchantInfo'
        '5303704' // VND
        '$amountField'
        '5802VN' // Country
        '$addInfoField'
        '6304'; // CRC placeholder prefix

    // CRC-16/CCITT-FALSE (poly=0x1021, init=0xFFFF) over payload+"6304"
    int crc = 0xFFFF;
    for (final byte in payload.codeUnits) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
      }
    }
    final crcHex = crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$payload$crcHex';
  }

  Widget _receipt(BuildContext context, InvoiceTemplate t) {
    final bfs = _bodyFs(t.fontSize);
    final lh = _lineH(t.lineSpacing);
    final isUnpaid = status == 'unpaid' || status == 'cancelled';

    // Effective values
    final effectiveDiscount = isUnpaid ? totalAmount : discountAmount;
    final effectiveDiscountPct = isUnpaid ? 100.0 : discountPercent;
    final effectiveNet = isUnpaid ? 0.0 : netTotal;
    final hasDiscount = effectiveDiscount > 0;

    final mono = TextStyle(
      fontFamily: 'Courier New',
      fontSize: bfs,
      height: lh,
      color: Colors.black87,
    );

    // ── Local helpers ─────────────────────────────────────────────────────────

    Widget dashedDiv() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '- - - - - - - - - - - - - - - - - - - - - - -',
            style: mono.copyWith(
                fontSize: bfs - 1, color: Colors.black38, height: 1),
            textAlign: TextAlign.center,
          ),
        );

    Widget solidDiv() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Divider(height: 1, thickness: 0.8, color: Colors.black26),
        );

    // Table row: Name | Qty | Amount
    Widget itemRow(String name, String qty, String amount,
        {bool isHeader = false}) {
      final s = isHeader
          ? mono.copyWith(fontWeight: FontWeight.w700)
          : mono;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isHeader ? 2 : lh),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: Text(name, style: s)),
            SizedBox(
                width: 36,
                child:
                    Text(qty, style: s, textAlign: TextAlign.right)),
            SizedBox(
                width: 72,
                child: Text(amount,
                    style: s, textAlign: TextAlign.right)),
          ],
        ),
      );
    }

    // Summary row (totals area)
    Widget summaryRow(String label, String value,
        {bool bold = false, Color? color}) {
      final s = bold
          ? mono.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: bfs + 1,
              color: color ?? Colors.black)
          : mono.copyWith(color: color ?? Colors.black87);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: s)),
            Text(value, style: s),
          ],
        ),
      );
    }

    // ── Cached logo image ─────────────────────────────────────────────────────
    Widget logoWidget() => _CachedNetworkImage(
          url: t.logoUrl!,
          height: t.logoHeight.toDouble().clamp(30.0, 120.0),
          fit: BoxFit.contain,
          errorWidget: () => const SizedBox.shrink(),
        );

    // ── Cached QR static image ────────────────────────────────────────────────
    Widget qrStaticWidget() => _CachedNetworkImage(
          url: t.qrStaticUrl!,
          height: 120,
          fit: BoxFit.contain,
          errorWidget: () => Text('[QR không tải được]',
              style: mono.copyWith(color: Colors.black38)),
        );

    // Dynamic VietQR — vẽ offline bằng qr_flutter (không cần internet)
    Widget qrDynamicWidget() {
      final qrData = _buildVietQrData(
        bankId: t.qrBankName ?? '',
        accountNumber: t.qrAccountNumber ?? '',
        accountName: t.qrAccountName,
        amountVnd: effectiveNet.toInt(),
        addInfo: 'Thanh toan hoa don $tableName',
      );
      return QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 130,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF1A1A1A),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF1A1A1A),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LOGO ─────────────────────────────────────────────────────────
          if (t.showLogo && t.logoUrl != null && t.logoUrl!.isNotEmpty) ...[
            Align(
              alignment: t.logoPosition == 'left'
                  ? Alignment.centerLeft
                  : t.logoPosition == 'right'
                      ? Alignment.centerRight
                      : Alignment.center,
              child: logoWidget(),
            ),
            const SizedBox(height: 8),
          ],

          // ── TÊN QUÁN ─────────────────────────────────────────────────────
          Text(
            t.storeName.toUpperCase(),
            textAlign: _toTextAlign(t.alignStoreName),
            style: mono.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: _storeNameFs(t.fontSizeStoreName),
              height: 1.2,
            ),
          ),

          // ── ĐỊA CHỈ ──────────────────────────────────────────────────────
          if (t.address != null && t.address!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              t.address!,
              textAlign: _toTextAlign(t.alignAddress),
              style: mono.copyWith(
                  fontSize: bfs - 0.5,
                  color: Colors.black54,
                  height: 1.3),
            ),
          ],

          // ── SĐT ──────────────────────────────────────────────────────────
          if (t.phone != null && t.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'ĐT: ${t.phone}',
              textAlign: _toTextAlign(t.alignPhone),
              style: mono.copyWith(
                  fontSize: bfs - 0.5, color: Colors.black54),
            ),
          ],

          dashedDiv(),

          // ── TIÊU ĐỀ ──────────────────────────────────────────────────────
          Text(
            t.title.toUpperCase(),
            textAlign: _toTextAlign(t.alignTitle),
            style: mono.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: _titleFs(t.fontSizeTitle),
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),

          // ── NGÀY GIỜ + META ───────────────────────────────────────────────
          const SizedBox(height: 6),
          Text('Ngày: ${_fmtDateTime(startTime)}',
              style: mono.copyWith(
                  fontSize: bfs - 0.5, color: Colors.black54)),
          if (t.showCashier) ...[
            const SizedBox(height: 1),
            Text(
              'Thu ngân: $cashierName'
              '${shiftLabel != null ? ' ($shiftLabel)' : ''}',
              style: mono.copyWith(
                  fontSize: bfs - 0.5, color: Colors.black54),
            ),
          ],
          if (t.showTableName) ...[
            const SizedBox(height: 1),
            Text('Bàn: $tableName',
                style: mono.copyWith(
                    fontSize: bfs - 0.5, color: Colors.black54)),
          ],
          if (t.showCustomer && member != null) ...[
            const SizedBox(height: 1),
            Text(
              'Khách hàng: ${member!['full_name'] ?? member!['name'] ?? ''}'
              '${(member!['tier'] ?? member!['tier_name']) != null ? ' (${member!['tier'] ?? member!['tier_name']})' : ''}',
              style: mono.copyWith(
                  fontSize: bfs - 0.5, color: Colors.black54),
            ),
          ],
          if (t.showCheckinCheckout) ...[
            const SizedBox(height: 1),
            Text(
              'Vào: ${_fmtTime(startTime)} | Ra: ${_fmtTime(endTime)}',
              style: mono.copyWith(
                  fontSize: bfs - 0.5, color: Colors.black54),
            ),
          ],
          if (t.showDuration) ...[
            const SizedBox(height: 1),
            Text('T.Gian chơi: ${_fmtDuration(playMinutes)}',
                style: mono.copyWith(
                    fontSize: bfs - 0.5, color: Colors.black54)),
          ],

          dashedDiv(),

          // ── BẢNG HÀNG: header ─────────────────────────────────────────────
          itemRow('Tên hàng', 'SL', 'T.Tiền', isHeader: true),
          solidDiv(),

          // ── Tiền giờ chơi (SL = số giờ, không hiện đơn giá) ─────────────
          itemRow(
            'Tiền giờ ($tableName)',
            _fmtHours(playMinutes), // e.g. "2.50h"
            _fmtCurrency(playAmount),
          ),

          // ── Sản phẩm / dịch vụ ───────────────────────────────────────────
          ...products.map((p) {
            final name = p['name']?.toString() ?? 'Sản phẩm';
            final qty = (p['qty'] as int?) ?? 0;
            final price = (p['price'] as double?) ?? 0.0;
            return itemRow(name, '$qty', _fmtCurrency(price * qty));
          }),

          solidDiv(),

          // ── TỔNG KẾT ─────────────────────────────────────────────────────
          // Cộng tiền hàng (chỉ khi có khuyến mãi)
          if (hasDiscount) ...[
            summaryRow('Cộng tiền hàng:', _fmtCurrency(totalAmount)),

            // Khuyến mãi / Chiết khấu
            summaryRow(
              effectiveDiscountPct > 0 && effectiveDiscountPct < 100
                  ? 'Khuyến mãi (${effectiveDiscountPct.toInt()}%):'
                  : 'Khuyến mãi:',
              '-${_fmtCurrency(effectiveDiscount)}',
              color: const Color(0xFFD97706),
            ),
            const SizedBox(height: 2),
          ],

          // TỔNG CỘNG
          summaryRow(
            'TỔNG CỘNG:',
            _fmtCurrency(effectiveNet),
            bold: true,
            color: isUnpaid
                ? const Color(0xFFDC2626)
                : const Color(0xFF2E4F4F),
          ),

          // ── GHI CHÚ / LÝ DO (không có badge trạng thái) ─────────────────
          if (note != null && note!.trim().isNotEmpty) ...[
            dashedDiv(),
            Text(
              isUnpaid ? 'Lý do:' : 'Ghi chú:',
              textAlign: TextAlign.center,
              style: mono.copyWith(
                  fontSize: bfs - 0.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              note!.trim(),
              textAlign: TextAlign.center,
              style: mono.copyWith(
                  fontSize: bfs - 0.5,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic),
            ),
          ],

          // ── QR THANH TOÁN ─────────────────────────────────────────────────
          if (t.showQrPayment && !isUnpaid) ...[
            dashedDiv(),
            Text(
              'MÃ QR THANH TOÁN QUÉT NHANH',
              textAlign: TextAlign.center,
              style: mono.copyWith(
                  fontSize: bfs - 0.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            if (t.qrType == 'static' &&
                t.qrStaticUrl != null &&
                t.qrStaticUrl!.isNotEmpty) ...[
              Center(child: qrStaticWidget()),
            ] else if (t.qrBankName != null &&
                t.qrBankName!.isNotEmpty &&
                t.qrAccountNumber != null &&
                t.qrAccountNumber!.isNotEmpty) ...[
              Center(child: qrDynamicWidget()),
              const SizedBox(height: 4),
              Text(
                'Ngân hàng: ${t.qrBankName}\n'
                'STK: ${t.qrAccountNumber}'
                '${t.qrAccountName != null && t.qrAccountName!.isNotEmpty ? '\nTên: ${t.qrAccountName}' : ''}',
                textAlign: TextAlign.center,
                style: mono.copyWith(
                    fontSize: bfs - 1, color: Colors.black54),
              ),
            ],
          ],

          // ── FOOTER MESSAGE ────────────────────────────────────────────────
          if (t.footerMessage != null && t.footerMessage!.isNotEmpty) ...[
            dashedDiv(),
            Text(
              t.footerMessage!,
              textAlign: _toTextAlign(t.alignFooter),
              style: mono.copyWith(
                  fontSize: bfs,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
