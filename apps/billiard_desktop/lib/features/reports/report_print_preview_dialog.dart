import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../billing/invoice_template_provider.dart';

// ─── Custom Painter for Dashed Lines ─────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;

  _DashedLinePainter({
    required this.color,
    this.dashWidth = 4.0,
    this.dashGap = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
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

// ─── Dialog widget ───────────────────────────────────────────────────────────

class ReportPrintPreviewDialog extends ConsumerWidget {
  final DateTimeRange dateRange;
  final String statusFilterLabel;
  final String cashierFilterLabel;
  final int totalInvoices;
  final double totalPlay;
  final double totalService;
  final double totalDiscount;
  final double totalAmount;
  final List<dynamic> orders;
  final bool showInvoiceList;

  const ReportPrintPreviewDialog({
    super.key,
    required this.dateRange,
    required this.statusFilterLabel,
    required this.cashierFilterLabel,
    required this.totalInvoices,
    required this.totalPlay,
    required this.totalService,
    required this.totalDiscount,
    required this.totalAmount,
    required this.orders,
    required this.showInvoiceList,
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

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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

  // ─── Print Logic ─────────────────────────────────────────────────────────────

  Future<Uint8List> _generateReportPdf(InvoiceTemplate t) async {
    final pdf = pw.Document();

    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      final fontDataReg = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      fontRegular = pw.Font.ttf(fontDataReg);
      final fontDataBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      fontBold = pw.Font.ttf(fontDataBold);
    } catch (e) {
      debugPrint('[ReportPrintPreviewDialog] Error loading local font, fallback to helvetica: $e');
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final bfs = _bodyFs(t.fontSize);

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

    // Group orders by day
    final Map<DateTime, double> dailyRevenue = {};
    for (final o in orders) {
      final raw = o as Map<String, dynamic>;
      final dateStr = (raw['end_time'] ?? raw['created_at'] ?? raw['start_time'] ?? '').toString().replaceAll(' ', 'T');
      if (dateStr.isEmpty) continue;
      try {
        final dt = DateTime.parse(dateStr);
        final dateKey = DateTime(dt.year, dt.month, dt.day);
        final double amount = _toDouble(raw['total_amount']);
        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + amount;
      } catch (_) {}
    }
    final sortedDays = dailyRevenue.keys.toList()..sort();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          72 * PdfPageFormat.mm,
          Platform.isWindows ? 400 * PdfPageFormat.mm : double.infinity,
          marginAll: 3 * PdfPageFormat.mm,
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

              // Địa chỉ & SĐT
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
                  ),
                ),
              ],
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

              // Tiêu đề báo cáo
              pw.Text(
                'BÁO CÁO DOANH THU',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: bfs + 3,
                  lineSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),

              // Cấu hình lọc
              _pdfMetaRow('Thời gian:', '${_fmtDate(dateRange.start)} - ${_fmtDate(dateRange.end)}', mono, monoBold),
              _pdfMetaRow('Trạng thái:', statusFilterLabel, mono, monoBold),
              _pdfMetaRow('Nhân viên:', cashierFilterLabel, mono, monoBold),

              pw.SizedBox(height: 6),
              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Tổng hợp số liệu
              _pdfMetaRow('Tổng số hóa đơn:', '$totalInvoices HĐ', mono, monoBold),
              pw.SizedBox(height: 4),
              _pdfSummaryRow('Tiền giờ:', _fmtCurrency(totalPlay), mono),
              _pdfSummaryRow('Tiền dịch vụ:', _fmtCurrency(totalService), mono),
              _pdfSummaryRow('Chiết khấu:', '-${_fmtCurrency(totalDiscount)}', mono),

              pw.SizedBox(height: 4),
              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Doanh thu theo ngày
              if (!showInvoiceList && sortedDays.isNotEmpty) ...[
                pw.Text(
                  'DOANH THU THEO NGÀY:',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: bfs,
                  ),
                ),
                pw.SizedBox(height: 4),
                for (final d in sortedDays)
                  _pdfSummaryRow(
                    '  ${_fmtDate(d)}:',
                    _fmtCurrency(dailyRevenue[d]!),
                    mono,
                  ),
                pw.SizedBox(height: 4),
                pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),
              ],

              // Tổng cộng doanh thu
              _pdfSummaryRow(
                'TỔNG DOANH THU:',
                _fmtCurrency(totalAmount),
                monoBold,
              ),

              pw.SizedBox(height: 6),
              pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),

              // Danh sách hoá đơn
              if (showInvoiceList && orders.isNotEmpty) ...[
                pw.Text(
                  'DANH SÁCH HÓA ĐƠN:',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: bfs,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(flex: 12, child: pw.Text('STT', style: monoBold, textAlign: pw.TextAlign.left)),
                    pw.Expanded(flex: 30, child: pw.Text('Bàn', style: monoBold, textAlign: pw.TextAlign.left)),
                    pw.Expanded(flex: 20, child: pw.Text('Vào', style: monoBold, textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 20, child: pw.Text('Ra', style: monoBold, textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 30, child: pw.Text('TT', style: monoBold, textAlign: pw.TextAlign.right)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 4),
                ...orders.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final o = entry.value as Map<String, dynamic>;
                  return _pdfInvoiceRow(idx, o, mono);
                }),
                pw.SizedBox(height: 6),
                pw.Text('------------------------------------------', style: mono, textAlign: pw.TextAlign.center),
              ],

              // Footer message
              pw.Text(
                'Ngày in báo cáo: ${_fmtDateTime(DateTime.now())}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: bfs - 0.5,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
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

  pw.Widget _pdfSummaryRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  pw.Widget _pdfInvoiceRow(int index, Map<String, dynamic> o, pw.TextStyle style) {
    final startStr = (o['start_time'] ?? '').toString();
    String startTimeText = '--:--';
    if (startStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(startStr.replaceAll(' ', 'T'));
        startTimeText = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final endStr = (o['end_time'] ?? '').toString();
    String endTimeText = '--:--';
    if (endStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(endStr.replaceAll(' ', 'T'));
        endTimeText = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final tt = _toDouble(o['total_amount']);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 12,
            child: pw.Text('${index + 1}', style: style, textAlign: pw.TextAlign.left),
          ),
          pw.Expanded(
            flex: 30,
            child: pw.Text('${o['table_name'] ?? 'N/A'}', style: style, textAlign: pw.TextAlign.left, maxLines: 1),
          ),
          pw.Expanded(
            flex: 20,
            child: pw.Text(startTimeText, style: style, textAlign: pw.TextAlign.center),
          ),
          pw.Expanded(
            flex: 20,
            child: pw.Text(endTimeText, style: style, textAlign: pw.TextAlign.center),
          ),
          pw.Expanded(
            flex: 30,
            child: pw.Text(_fmtCurrency(tt), style: style, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  void _setupDefaultPrinter(BuildContext context) async {
    try {
      final printer = await Printing.pickPrinter(context: context);
      if (printer != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('default_printer_name', printer.name);
        await prefs.setString('default_printer_url', printer.url);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cài máy in mặc định: ${printer.name}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cài đặt máy in: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _doPrint(BuildContext context, InvoiceTemplate t) async {
    try {
      final pdfBytes = await _generateReportPdf(t);
      final prefs = await SharedPreferences.getInstance();
      final defaultPrinterName = prefs.getString('default_printer_name');
      final defaultPrinterUrl = prefs.getString('default_printer_url');

      final targetFormat = PdfPageFormat(
        72 * PdfPageFormat.mm,
        Platform.isWindows ? 400 * PdfPageFormat.mm : double.infinity,
        marginAll: 3 * PdfPageFormat.mm,
      );

      if (defaultPrinterName != null && defaultPrinterUrl != null) {
        final printers = await Printing.listPrinters();
        Printer? targetPrinter;
        for (final p in printers) {
          if (p.url == defaultPrinterUrl || p.name == defaultPrinterName) {
            targetPrinter = p;
            break;
          }
        }

        if (targetPrinter != null) {
          final success = await Printing.directPrintPdf(
            printer: targetPrinter,
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'Bao_cao_doanh_thu',
            format: targetFormat,
          );
          if (success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã gửi lệnh in trực tiếp đến: $defaultPrinterName'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Bao_cao_doanh_thu',
        format: targetFormat,
      );
    } catch (e) {
      debugPrint('[ReportPrintPreviewDialog] print error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi in báo cáo: $e'),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          child: _reportPaper(context, InvoiceTemplate.defaultTemplate),
        ),
        data: (t) => _shell(context, t, child: _reportPaper(context, t)),
      ),
    );
  }

  // ─── Dialog Shell ────────────────────────────────────────────────────────────

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
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('XEM TRƯỚC BÁO CÁO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          )),
                      Text('Mẫu in K80 · 80mm',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),

          // Scrollable report paper
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => _setupDefaultPrinter(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.print_disabled_outlined, size: 20, tooltip: 'Cài máy in mặc định'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _doPrint(context, t),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('In báo cáo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ─── Report Paper View ───────────────────────────────────────────────────────

  Widget _reportPaper(BuildContext context, InvoiceTemplate t) {
    final bfs = _bodyFs(t.fontSize);
    final lh = _lineH(t.lineSpacing);

    final baseStyle = TextStyle(
      fontSize: bfs,
      height: lh,
      color: const Color(0xFF1A1A1A),
    );

    // Helpers
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
          child: Divider(height: 1, thickness: 0.8, color: Colors.black26),
        );

    Widget metaRow(String label, String value, {bool isBold = false}) {
      final style = isBold
          ? baseStyle.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))
          : baseStyle.copyWith(color: const Color(0xFF5A5A5A));

      final valStyle = isBold
          ? baseStyle.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF1A1A1A))
          : baseStyle.copyWith(color: const Color(0xFF1A1A1A));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: style),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: valStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    Widget summaryRow(String label, String value, {bool bold = false, Color? color}) {
      final style = bold
          ? baseStyle.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: bfs + 1,
              color: color ?? const Color(0xFF1A1A1A),
            )
          : baseStyle.copyWith(color: color ?? const Color(0xFF1A1A1A));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      );
    }

    final colStyle = baseStyle;
    final headerStyle = colStyle.copyWith(fontWeight: FontWeight.bold);

    Widget invoiceRow(int index, Map<String, dynamic> o) {
      final startStr = (o['start_time'] ?? '').toString();
      String startTimeText = '--:--';
      if (startStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(startStr.replaceAll(' ', 'T'));
          startTimeText = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}
      }

      final endStr = (o['end_time'] ?? '').toString();
      String endTimeText = '--:--';
      if (endStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(endStr.replaceAll(' ', 'T'));
          endTimeText = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}
      }

      final tt = _toDouble(o['total_amount']);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            Expanded(
              flex: 12,
              child: Text(
                '${index + 1}',
                style: colStyle,
                textAlign: TextAlign.left,
              ),
            ),
            Expanded(
              flex: 30,
              child: Text(
                '${o['table_name'] ?? 'N/A'}',
                style: colStyle,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                startTimeText,
                style: colStyle,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                endTimeText,
                style: colStyle,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 30,
              child: Text(
                _fmtCurrency(tt),
                style: colStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    // Group orders by day
    final Map<DateTime, double> dailyRevenue = {};
    for (final o in orders) {
      final raw = o as Map<String, dynamic>;
      final dateStr = (raw['end_time'] ?? raw['created_at'] ?? raw['start_time'] ?? '').toString().replaceAll(' ', 'T');
      if (dateStr.isEmpty) continue;
      try {
        final dt = DateTime.parse(dateStr);
        final dateKey = DateTime(dt.year, dt.month, dt.day);
        final double amount = _toDouble(raw['total_amount']);
        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + amount;
      } catch (_) {}
    }

    final sortedDays = dailyRevenue.keys.toList()..sort();

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
              child: Image.asset(
                'assets/images/logo.png',
                height: t.logoHeight.toDouble().clamp(30.0, 120.0),
                width: t.logoWidth.toDouble().clamp(30.0, 300.0),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // ── TÊN QUÁN ─────────────────────────────────────────────────────
          if (t.showStoreName) ...[
            Text(
              t.storeName.toUpperCase(),
              textAlign: _toTextAlign(t.alignStoreName),
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: _storeNameFs(t.fontSizeStoreName),
                height: 1.2,
              ),
            ),
          ],

          // ── ĐỊA CHỈ & SĐT ─────────────────────────────────────────────────
          if (t.address != null && t.address!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              t.address!,
              textAlign: _toTextAlign(t.alignAddress),
              style: baseStyle.copyWith(
                  fontSize: bfs - 0.5,
                  color: const Color(0xFF3A3A3A),
                  height: 1.3),
            ),
          ],
          if (t.phone != null && t.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'ĐT: ${t.phone}',
              textAlign: _toTextAlign(t.alignPhone),
              style: baseStyle.copyWith(
                  fontSize: bfs - 0.5, color: const Color(0xFF3A3A3A)),
            ),
          ],

          dashedDiv(),

          // ── TIÊU ĐỀ BÁO CÁO ──────────────────────────────────────────────
          Text(
            'BÁO CÁO DOANH THU',
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: bfs + 3,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // ── CẤU HÌNH LỌC ─────────────────────────────────────────────────
          metaRow('Thời gian:', '${_fmtDate(dateRange.start)} - ${_fmtDate(dateRange.end)}'),
          metaRow('Trạng thái:', statusFilterLabel),
          metaRow('Nhân viên:', cashierFilterLabel),

          dashedDiv(),

          // ── TỔNG HỢP SỐ LIỆU ──────────────────────────────────────────────
          metaRow('Tổng số hóa đơn:', '$totalInvoices HĐ', isBold: true),
          const SizedBox(height: 4),

          summaryRow('Tiền giờ:', _fmtCurrency(totalPlay)),
          summaryRow('Tiền dịch vụ:', _fmtCurrency(totalService)),
          summaryRow(
            'Chiết khấu:',
            '-${_fmtCurrency(totalDiscount)}',
            color: const Color(0xFFD97706),
          ),

          solidDiv(),

          // ── DOANH THU THEO NGÀY (chỉ hiển thị ở tab Tổng hợp) ─────────────
          if (!showInvoiceList && sortedDays.isNotEmpty) ...[
            Text(
              'DOANH THU THEO NGÀY:',
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: bfs,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            for (final d in sortedDays)
              summaryRow(
                '  ${_fmtDate(d)}:',
                _fmtCurrency(dailyRevenue[d]!),
              ),
            solidDiv(),
          ],

          // ── TỔNG CỘNG DOANH THU ───────────────────────────────────────────
          summaryRow(
            'TỔNG DOANH THU:',
            _fmtCurrency(totalAmount),
            bold: true,
            color: const Color(0xFF2E4F4F),
          ),

          dashedDiv(),

          // ── DANH SÁCH HOÁ ĐƠN (TAB CHI TIẾT) ─────────────────────────────
          if (showInvoiceList && orders.isNotEmpty) ...[
            Text(
              'DANH SÁCH HÓA ĐƠN:',
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: bfs,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 12,
                  child: Text(
                    'STT',
                    style: headerStyle,
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: Text(
                    'Bàn',
                    style: headerStyle,
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'Vào',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'Ra',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: Text(
                    'TT',
                    style: headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Divider(height: 1, thickness: 0.5, color: Colors.black26),
            const SizedBox(height: 4),
            for (int index = 0; index < orders.length; index++)
              invoiceRow(index, orders[index] as Map<String, dynamic>),
            dashedDiv(),
          ],

          // ── FOOTER MESSAGE ────────────────────────────────────────────────
          Text(
            'Ngày in báo cáo: ${_fmtDateTime(DateTime.now())}',
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(
                fontSize: bfs - 0.5,
                color: const Color(0xFF3A3A3A),
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
