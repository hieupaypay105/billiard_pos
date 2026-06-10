import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/config/env_config.dart';
import '../../core/constants/app_colors.dart';
import 'invoice_template_provider.dart';

// ─── Lightweight cached image widget ──────────────────────────────────────────
//
// Dùng dio + path_provider để cache ảnh về thư mục temp của thiết bị.
// File cache được đặt tên theo MD5 của URL để tránh tải lại không cần thiết.
// Chỉ tải lại khi file cache không tồn tại (server thay URL → tự hết cache cũ).

class _CachedNetworkImage extends StatefulWidget {
  final String url;
  final double? height;
  final BoxFit fit;
  final Widget Function()? errorWidget;

  const _CachedNetworkImage({
    required this.url,
    this.height,
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
    try {
      final cacheDir = await getTemporaryDirectory();

      // Resolve relative URL if it does not start with http/https
      String resolvedUrl = url;
      if (!url.startsWith('http')) {
        final apiUri = Uri.parse(EnvConfig.apiBaseUrl);
        final host = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ":${apiUri.port}" : ""}';
        
        // Extract base path (e.g., /billiard_pos_crm) if present in apiBaseUrl
        String basePath = '';
        final apiPath = apiUri.path;
        if (apiPath.endsWith('/api')) {
          basePath = apiPath.substring(0, apiPath.length - 4);
        } else if (apiPath.contains('/api/')) {
          final idx = apiPath.indexOf('/api/');
          basePath = apiPath.substring(0, idx);
        } else {
          final segments = apiUri.pathSegments;
          if (segments.isNotEmpty) {
            basePath = '/${segments.sublist(0, segments.length - 1).join('/')}';
          }
        }
        if (basePath == '/') basePath = '';

        // Ensure url has a leading slash
        final normalizedPath = url.startsWith('/') ? url : '/$url';
        
        // Avoid prepending basePath twice if it's already there
        if (basePath.isNotEmpty && normalizedPath.startsWith(basePath)) {
          resolvedUrl = '$host$normalizedPath';
        } else {
          resolvedUrl = '$host$basePath$normalizedPath';
        }
        debugPrint('[_CachedNetworkImage] resolved relative URL: $url -> $resolvedUrl');
      }

      final hash = md5.convert(resolvedUrl.codeUnits).toString();
      final ext = resolvedUrl.contains('.png') ? 'png' : 'jpg';
      final file = File('${cacheDir.path}/invoice_img_$hash.$ext');
      if (await file.exists()) return file;

      debugPrint('[_CachedNetworkImage] downloading: $resolvedUrl');
      final res = await Dio().get<List<int>>(
        resolvedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.data != null) {
        await file.writeAsBytes(res.data!);
        debugPrint('[_CachedNetworkImage] cached to: ${file.path}');
        return file;
      }
      throw Exception('Empty data response');
    } catch (e, stack) {
      debugPrint('[_CachedNetworkImage] error loading logo image: $url -> error: $e\n$stack');
      rethrow;
    }
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

  Future<Uint8List> _generateInvoicePdf(InvoiceTemplate t) async {
    final pdf = pw.Document();

    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      final fontDataReg = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      fontRegular = pw.Font.ttf(fontDataReg);
      final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      fontBold = pw.Font.ttf(fontDataBold);
    } catch (e) {
      debugPrint('[InvoicePrintPreviewDialog] Error loading local font, fallback to helvetica: $e');
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final bfs = _bodyFs(t.fontSize);
    final isUnpaid = status == 'unpaid' || status == 'cancelled';
    final effectiveDiscount = isUnpaid ? totalAmount : discountAmount;
    final effectiveDiscountPct = isUnpaid ? 100.0 : discountPercent;
    final effectiveNet = isUnpaid ? 0.0 : netTotal;
    final hasDiscount = effectiveDiscount > 0;

    final mono = pw.TextStyle(
      font: fontRegular,
      fontSize: bfs,
      color: PdfColors.black,
    );
    final monoBold = pw.TextStyle(
      font: fontBold,
      fontSize: bfs,
      color: PdfColors.black,
    );

    pw.MemoryImage? logoImage;
    if (t.showLogo) {
      try {
        final logoBytes = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          Platform.isWindows ? 250 * PdfPageFormat.mm : double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Logo
              if (t.showLogo && logoImage != null) ...[
                pw.Align(
                  alignment: t.logoPosition == 'left'
                      ? pw.Alignment.centerLeft
                      : t.logoPosition == 'right'
                          ? pw.Alignment.centerRight
                          : pw.Alignment.center,
                  child: pw.Image(
                    logoImage,
                    height: t.logoHeight.toDouble().clamp(30.0, 120.0),
                    width: t.logoWidth.toDouble().clamp(30.0, 300.0),
                  ),
                ),
                pw.SizedBox(height: 4),
              ],

              // Tên quán
              if (t.showStoreName) ...[
                pw.Text(
                  t.storeName.toUpperCase(),
                  textAlign: t.alignStoreName == 'left'
                      ? pw.TextAlign.left
                      : t.alignStoreName == 'right'
                          ? pw.TextAlign.right
                          : pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: _storeNameFs(t.fontSizeStoreName),
                    lineSpacing: 1.2,
                  ),
                ),
              ],

              // Địa chỉ
              if (t.address != null && t.address!.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  t.address!,
                  textAlign: t.alignAddress == 'left'
                      ? pw.TextAlign.left
                      : t.alignAddress == 'right'
                          ? pw.TextAlign.right
                          : pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: bfs - 0.5,
                    lineSpacing: 1.3,
                  ),
                ),
              ],

              // SĐT
              if (t.phone != null && t.phone!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'ĐT: ${t.phone}',
                  textAlign: t.alignPhone == 'left'
                      ? pw.TextAlign.left
                      : t.alignPhone == 'right'
                          ? pw.TextAlign.right
                          : pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: bfs - 0.5,
                  ),
                ),
              ],

              pw.SizedBox(height: 6),
              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Tiêu đề
              pw.Text(
                t.title.toUpperCase(),
                textAlign: t.alignTitle == 'left'
                    ? pw.TextAlign.left
                    : t.alignTitle == 'right'
                        ? pw.TextAlign.right
                        : pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: _titleFs(t.fontSizeTitle),
                  lineSpacing: 1.2,
                ),
              ),

              // Meta rows
              pw.SizedBox(height: 6),
              _pdfMetaRow('Ngày:', _fmtDateTime(startTime), mono, monoBold),
              if (t.showCashier) ...[
                _pdfMetaRow(
                  'Thu ngân:',
                  '$cashierName${shiftLabel != null ? ' ($shiftLabel)' : ''}',
                  mono,
                  monoBold,
                ),
              ],
              if (t.showTableName) ...[
                _pdfMetaRow('Bàn:', tableName, mono, monoBold),
              ],
              if (t.showCustomer && member != null) ...[
                _pdfMetaRow(
                  'Khách hàng:',
                  '${member!['full_name'] ?? member!['name'] ?? ''}'
                  '${(member!['tier'] ?? member!['tier_name']) != null ? ' (${member!['tier'] ?? member!['tier_name']})' : ''}',
                  mono,
                  monoBold,
                ),
              ],
              if (t.showCheckinCheckout && (hourlyRate > 0 || playMinutes > 0 || playAmount > 0)) ...[
                _pdfMetaRow(
                  'Giờ vào / ra:',
                  '${_fmtTime(startTime)} - ${_fmtTime(endTime)}',
                  mono,
                  monoBold,
                ),
              ],
              if (t.showDuration && (hourlyRate > 0 || playMinutes > 0 || playAmount > 0)) ...[
                _pdfMetaRow('Thời lượng chơi:', _fmtDuration(playMinutes), mono, monoBold),
              ],

              pw.SizedBox(height: 6),
              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Bảng hàng header
              _pdfItemRow('Tên hàng', 'SL', 'T.Tiền', monoBold, isHeader: true),
              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Tiền giờ chơi
              if (hourlyRate > 0 || playAmount > 0) ...[
                _pdfItemRow(
                  'Tiền giờ ($tableName)',
                  _fmtHours(playMinutes),
                  _fmtCurrency(playAmount),
                  mono,
                ),
              ],

              // Dịch vụ
              ...products.map((p) {
                final name = p['name']?.toString() ?? 'Sản phẩm';
                final qty = (p['qty'] as int?) ?? 0;
                final price = (p['price'] as double?) ?? 0.0;
                return _pdfItemRow(name, '$qty', _fmtCurrency(price * qty), mono);
              }),

              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Tổng kết
              if (hasDiscount) ...[
                _pdfSummaryRow('Cộng tiền hàng:', _fmtCurrency(totalAmount), mono),
                _pdfSummaryRow(
                  effectiveDiscountPct > 0 && effectiveDiscountPct < 100
                      ? 'Khuyến mãi (${effectiveDiscountPct.toInt()}%):'
                      : 'Khuyến mãi:',
                  '-${_fmtCurrency(effectiveDiscount)}',
                  mono,
                ),
                pw.SizedBox(height: 2),
              ],

              // TỔNG CỘNG
              _pdfSummaryRow(
                'TỔNG CỘNG:',
                _fmtCurrency(effectiveNet),
                monoBold,
              ),

              // Lý do / Ghi chú
              if (note != null && note!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),
                pw.Text(
                  isUnpaid ? 'Lý do:' : 'Ghi chú:',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: bfs - 0.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  note!.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: bfs - 0.5,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],

              // QR Thanh toán
              if (t.showQrPayment && !isUnpaid) ...[
                pw.SizedBox(height: 6),
                pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),
                pw.Text(
                  'MÃ QR THANH TOÁN QUÉT NHANH',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: bfs - 0.5,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: _buildVietQrData(
                        bankId: t.qrBankName ?? '',
                        accountNumber: t.qrAccountNumber ?? '',
                        accountName: t.qrAccountName,
                        amountVnd: effectiveNet.toInt(),
                        addInfo: 'Thanh toan hoa don $tableName',
                      ),
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Ngân hàng: ${t.qrBankName}\n'
                  'STK: ${t.qrAccountNumber}'
                  '${t.qrAccountName != null && t.qrAccountName!.isNotEmpty ? '\nTên: ${t.qrAccountName}' : ''}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: bfs - 1,
                  ),
                ),
              ],

              // Footer message
              if (t.footerMessage != null && t.footerMessage!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),
                pw.Text(
                  t.footerMessage!,
                  textAlign: t.alignFooter == 'left'
                      ? pw.TextAlign.left
                      : t.alignFooter == 'right'
                          ? pw.TextAlign.right
                          : pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: bfs,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfMetaRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: valStyle,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfItemRow(String name, String qty, String amount, pw.TextStyle style, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 6, child: pw.Text(name, style: style)),
          pw.SizedBox(
              width: 36,
              child: pw.Text(qty, style: style, textAlign: pw.TextAlign.right)),
          pw.SizedBox(
              width: 72,
              child: pw.Text(amount, style: style, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  void _doPrint(BuildContext context, InvoiceTemplate t) async {
    try {
      final pdfBytes = await _generateInvoicePdf(t);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Hoa_don_${tableName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      debugPrint('[InvoicePrintPreviewDialog] print error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi in hóa đơn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          InvoiceTemplate.defaultTemplate,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (_, __) => _shell(
          context,
          InvoiceTemplate.defaultTemplate,
          child: _receipt(context, InvoiceTemplate.defaultTemplate),
        ),
        data: (t) => _shell(context, t, child: _receipt(context, t)),
      ),
    );
  }

  // ─── Outer shell ─────────────────────────────────────────────────────────────

  Widget _shell(BuildContext context, InvoiceTemplate t, {required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 420 ? 380.0 : screenWidth - 40;
    return Container(
      width: dialogWidth,
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
            decoration: const BoxDecoration(
              color: Color(0xFF0F1923),
              borderRadius: BorderRadius.vertical(
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
                    onPressed: () => _doPrint(context, t),
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

  // ─── VietQR / EMV QRCPS string builder ───────────────────────────────────────
  //
  // Chuẩn EMV QRCPS / VietQR (NAPAS). Cấu trúc tag 38:
  //   00 10 A000000727         ← GUID cố định của NAPAS (không đổi)
  //   01 <len>                 ← Payment network specific
  //       00 06 <BIN 6 số>     ← BIN code ngân hàng (VD: 970415)
  //       01 <len> <account>   ← Số tài khoản
  //   02 08 QRIBFTTA           ← Service code cố định
  //
  // CRC-16/CCITT-FALSE (poly=0x1021, init=0xFFFF) tính trên toàn payload kể
  // cả prefix "6304" — kết quả append vào cuối dưới dạng HEX 4 ký tự.
  static String _buildVietQrData({
    required String bankId,
    required String accountNumber,
    String? accountName,
    int amountVnd = 0,
    String addInfo = '',
  }) {
    // 1. Sanitize bankId and resolve BIN
    final cleanBank = bankId.trim().toLowerCase();
    String bin = '970415'; // Default fallback (VietinBank)

    if (RegExp(r'^\d{6}$').hasMatch(cleanBank)) {
      bin = cleanBank;
    } else {
      final norm = cleanBank
          .replaceAll(RegExp(r'[^\w\s\u00C0-\u1EF9]'), '')
          .replaceAll(RegExp(r'\s+'), '');

      if (norm.contains('vietcombank') || norm.contains('vcb') || norm.contains('vietcom')) {
        bin = '970436';
      } else if (norm.contains('vietinbank') || norm.contains('vietin') || norm.contains('icb') || norm.contains('ctg')) {
        bin = '970415';
      } else if (norm.contains('techcombank') || norm.contains('tcb') || norm.contains('techcom')) {
        bin = '970407';
      } else if (norm.contains('agribank') || norm.contains('agri') || norm.contains('vba')) {
        bin = '970405';
      } else if (norm.contains('mbbank') || norm.contains('mb')) {
        bin = '970422';
      } else if (norm.contains('bidv')) {
        bin = '970418';
      } else if (norm.contains('acb')) {
        bin = '970416';
      } else if (norm.contains('vpbank') || norm.contains('vpb')) {
        bin = '970432';
      } else if (norm.contains('tpbank') || norm.contains('tpb')) {
        bin = '970423';
      } else if (norm.contains('sacombank') || norm.contains('stb') || norm.contains('sacom')) {
        bin = '970403';
      } else if (norm.contains('hdbank') || norm.contains('hdb')) {
        bin = '970437';
      } else if (norm.contains('shb')) {
        bin = '970443';
      } else if (norm.contains('ocb')) {
        bin = '970448';
      } else if (norm.contains('seabank') || norm.contains('seab')) {
        bin = '970440';
      } else if (norm.contains('abbank') || norm.contains('abb')) {
        bin = '970425';
      } else if (norm.contains('vib')) {
        bin = '970441';
      } else if (norm.contains('msb')) {
        bin = '970426';
      } else if (norm.contains('namabank') || norm.contains('nab')) {
        bin = '970428';
      } else if (norm.contains('pvcombank') || norm.contains('pvcb')) {
        bin = '970412';
      } else if (norm.contains('scb')) {
        bin = '970429';
      } else if (norm.contains('ncb')) {
        bin = '970419';
      } else if (norm.contains('eximbank') || norm.contains('eib')) {
        bin = '970431';
      } else if (norm.contains('baovietbank') || norm.contains('bvb')) {
        bin = '970438';
      } else if (norm.contains('lpbank') || norm.contains('lpb') || norm.contains('lienviet') || norm.contains('lienvietpostbank')) {
        bin = '970449';
      } else if (norm.contains('kienlong') || norm.contains('klb')) {
        bin = '970452';
      } else if (norm.contains('saigonbank') || norm.contains('sgicb')) {
        bin = '970400';
      } else if (norm.contains('bacabank') || norm.contains('bab')) {
        bin = '970409';
      } else if (norm.contains('vietabank') || norm.contains('vab')) {
        bin = '970427';
      } else if (norm.contains('vietbank')) {
        bin = '970433';
      } else if (norm.contains('pgbank') || norm.contains('pgb')) {
        bin = '970430';
      } else if (norm.contains('shinhan')) {
        bin = '970424';
      } else if (norm.contains('woori')) {
        bin = '970457';
      }
    }

    // 2. Sanitize account number (remove any spaces, dashes, or special characters)
    final cleanAcc = accountNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // TLV: ID (2 char) + Length (2 char, zero-padded) + Value
    String tlv(String id, String value) =>
        '$id${value.length.toString().padLeft(2, '0')}$value';

    // ── Tag 38: Merchant Account Information (VietQR / NAPAS) ────────────────
    // Sub-tag 00: GUID cố định của NAPAS
    final guidSub = tlv('00', 'A000000727');

    // Sub-tag 01: Payment network specific
    //   Sub-sub-tag 00: BIN ngân hàng
    //   Sub-sub-tag 01: Số tài khoản
    final bankBinSub = tlv('00', bin);
    final acctSub    = tlv('01', cleanAcc);
    final netSub     = tlv('01', '$bankBinSub$acctSub');

    // Sub-tag 02: Service code cố định
    final serviceSub = tlv('02', 'QRIBFTTA');

    final merchantInfo = tlv('38', '$guidSub$netSub$serviceSub');

    // ── Tag 54: Transaction Amount ─────────────────────────────────────────────
    final amountField = amountVnd > 0 ? tlv('54', amountVnd.toString()) : '';

    // ── Tag 62: Additional Data ────────────────────────────────────────────────
    // Sub-tag 08: Bill number / thông tin thanh toán (ASCII only, tối đa 25 ký tự)
    final addInfoAscii = addInfo
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final addInfoTrimmed = addInfoAscii.length > 25
        ? addInfoAscii.substring(0, 25)
        : addInfoAscii;
    final addInfoField = addInfoTrimmed.isNotEmpty
        ? tlv('62', tlv('08', addInfoTrimmed))
        : '';

    // ── Dynamic Point of Initiation Method ─────────────────────────────────────
    final pointOfInitiation = amountVnd > 0 ? '010212' : '010211';

    // ── Ghép payload (không có CRC value) ─────────────────────────────────────
    final payload = '000201'     // Payload Format Indicator = 01
        '$pointOfInitiation'     // Point of Initiation = 12 (dynamic) or 11 (static)
        '$merchantInfo'          // Tag 38
        '5303704'                // Currency = 704 (VND)
        '$amountField'           // Tag 54 (nếu có)
        '5802VN'                 // Country = VN
        '$addInfoField'          // Tag 62 (nếu có)
        '6304';                  // CRC tag prefix (value tính bên dưới)

    // ── CRC-16/CCITT-FALSE ─────────────────────────────────────────────────────
    // poly = 0x1021, init = 0xFFFF, no reflection (MSB-first)
    int crc = 0xFFFF;
    for (final byte in payload.codeUnits) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
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
      fontSize: bfs,
      height: lh,
      color: const Color(0xFF1A1A1A),
    );

    // ── Local helpers ─────────────────────────────────────────────────────────

    Widget metaRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: mono.copyWith(fontSize: bfs - 0.5, color: const Color(0xFF5A5A5A))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: mono.copyWith(fontSize: bfs - 0.5, color: const Color(0xFF1A1A1A)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    Widget dashedDiv() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(
              color: Colors.black26,
              dashWidth: 4,
              dashGap: 3,
            ),
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

    // ── Asset logo image ─────────────────────────────────────────────────────
    Widget logoWidget() => Image.asset(
          'assets/images/logo.png',
          height: t.logoHeight.toDouble().clamp(30.0, 120.0),
          width: t.logoWidth.toDouble().clamp(30.0, 300.0),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LOGO ─────────────────────────────────────────────────────────
          if (t.showLogo) ...[
            Align(
              alignment: t.logoPosition == 'left'
                  ? Alignment.centerLeft
                  : t.logoPosition == 'right'
                      ? Alignment.centerRight
                      : Alignment.center,
              child: logoWidget(),
            ),
            const SizedBox(height: 4),
          ],

          // ── TÊN QUÁN ─────────────────────────────────────────────────────
          if (t.showStoreName) ...[
            Text(
              t.storeName.toUpperCase(),
              textAlign: _toTextAlign(t.alignStoreName),
              style: mono.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: _storeNameFs(t.fontSizeStoreName),
                height: 1.2,
              ),
            ),
          ],

          // ── ĐỊA CHỈ ──────────────────────────────────────────────────────
          if (t.address != null && t.address!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              t.address!,
              textAlign: _toTextAlign(t.alignAddress),
              style: mono.copyWith(
                  fontSize: bfs - 0.5,
                  color: const Color(0xFF3A3A3A),
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
                  fontSize: bfs - 0.5, color: const Color(0xFF3A3A3A)),
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
          metaRow('Ngày:', _fmtDateTime(startTime)),
          if (t.showCashier) ...[
            metaRow(
              'Thu ngân:',
              '$cashierName${shiftLabel != null ? ' ($shiftLabel)' : ''}',
            ),
          ],
          if (t.showTableName) ...[
            metaRow('Bàn:', tableName),
          ],
          if (t.showCustomer && member != null) ...[
            metaRow(
              'Khách hàng:',
              '${member!['full_name'] ?? member!['name'] ?? ''}'
              '${(member!['tier'] ?? member!['tier_name']) != null ? ' (${member!['tier'] ?? member!['tier_name']})' : ''}',
            ),
          ],
          if (t.showCheckinCheckout && (hourlyRate > 0 || playMinutes > 0 || playAmount > 0)) ...[
            metaRow(
              'Giờ vào / ra:',
              '${_fmtTime(startTime)} - ${_fmtTime(endTime)}',
            ),
          ],
          if (t.showDuration && (hourlyRate > 0 || playMinutes > 0 || playAmount > 0)) ...[
            metaRow('Thời lượng chơi:', _fmtDuration(playMinutes)),
          ],

          dashedDiv(),

          // ── BẢNG HÀNG: header ─────────────────────────────────────────────
          itemRow('Tên hàng', 'SL', 'T.Tiền', isHeader: true),
          solidDiv(),

          // ── Tiền giờ chơi (SL = số giờ, không hiện đơn giá) ─────────────
          if (hourlyRate > 0 || playAmount > 0)
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
                  color: const Color(0xFF3A3A3A)),
            ),
            const SizedBox(height: 2),
            Text(
              note!.trim(),
              textAlign: TextAlign.center,
              style: mono.copyWith(
                  fontSize: bfs - 0.5,
                  color: const Color(0xFF3A3A3A),
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
                    fontSize: bfs - 1, color: const Color(0xFF3A3A3A)),
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
                  color: const Color(0xFF3A3A3A),
                  fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  _DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 4.0,
    this.dashGap = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
