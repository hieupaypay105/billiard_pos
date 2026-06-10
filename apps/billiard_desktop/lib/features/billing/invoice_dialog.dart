import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../auth/auth_provider.dart';
import '../tables/shift_provider.dart';
import 'invoice_print_preview_dialog.dart';

class InvoiceDialog extends ConsumerStatefulWidget {
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
  final String initialStatus;
  final String? note;
  final Future<void> Function({
    required String status,
    required String? paymentMethod,
    required double discountAmount,
    required double netTotal,
    required String? note,
  }) onConfirm;

  const InvoiceDialog({
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
    required this.initialStatus,
    this.note,
    required this.onConfirm,
  });

  @override
  ConsumerState<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends ConsumerState<InvoiceDialog> {
  late String _selectedStatus;
  final TextEditingController _reasonController = TextEditingController();
  String? _reasonError;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()} đ';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final cashierName = currentUser?.displayName ?? currentUser?.username ?? 'Hệ thống';
    final shiftState = ref.watch(shiftProvider);
    final activeShift = shiftState.activeShift;

    final isUnpaid = _selectedStatus == 'unpaid';
    final currentDiscountPercent = isUnpaid ? 100.0 : widget.discountPercent;
    final currentDiscountAmount = isUnpaid ? widget.totalAmount : widget.discountAmount;
    final currentNetTotal = isUnpaid ? 0.0 : widget.netTotal;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HÓA ĐƠN THANH TOÁN',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          widget.tableName,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Body (1 Column Compact) ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Time info combined
                    if (widget.hourlyRate > 0) ...[
                      _InfoRow(
                          'Thời gian',
                          '${_fmtTime(widget.startTime)} - ${_fmtTime(widget.endTime)} (${widget.playMinutes} phút)',
                          Icons.access_time_rounded),
                      _InfoRow(
                          'Đơn giá',
                          '${_fmtCurrency(widget.hourlyRate)}/giờ',
                          Icons.attach_money),
                    ],
                    _InfoRow(
                        'Ngày tạo HĐ',
                        _fmtDateTime(widget.startTime),
                        Icons.calendar_today_outlined),
                    _InfoRow(
                        'Ca thu ngân',
                        activeShift != null
                            ? '$cashierName (Ca ${activeShift.id.replaceAll('shift-', '')})'
                            : '$cashierName (Mặc định)',
                        Icons.person_outline),
                    if (widget.member != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thành viên: ${widget.member!['full_name']} (${widget.member!['tier']})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.hourlyRate > 0) ...[
                      const SizedBox(height: 8),
                      // Play amount box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('Tiền giờ chơi:',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                            const Spacer(),
                            Text(_fmtCurrency(widget.playAmount),
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],

                    // Products
                    if (widget.products.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Dịch vụ đi kèm:',
                          style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
                      const SizedBox(height: 4),
                      ...widget.products.map((p) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              Text(
                                  '${p['name']} × ${p['qty']}',
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                              const Spacer(),
                              Text(
                                _fmtCurrency(
                                    (p['price'] as double) *
                                        (p['qty'] as int)),
                                style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
                              ),
                            ]),
                          )),
                    ],

                    const Divider(height: 16, thickness: 1),
                    if (currentDiscountPercent > 0) ...[
                      Row(children: [
                        const Text('Tạm tính', style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(_fmtCurrency(widget.totalAmount),
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('Chiết khấu (${currentDiscountPercent.toInt()}%)', style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.accent)),
                        const Spacer(),
                        Text('-${_fmtCurrency(currentDiscountAmount)}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: AppColors.accent)),
                      ]),
                      const SizedBox(height: 6),
                    ],
                    // Total
                    Row(children: [
                      const Text('TỔNG THANH TOÁN',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const Spacer(),
                      Text(_fmtCurrency(currentNetTotal),
                          style: AppTextStyles.currency.copyWith(fontSize: 18)),
                    ]),

                    const SizedBox(height: 16),
                    // Payment selector
                    Text('Trạng thái hóa đơn:',
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ('paid', 'Thanh toán', Icons.check_circle_rounded,
                            AppColors.primary),
                        ('unpaid', 'Không thanh toán', Icons.money_off_rounded,
                            AppColors.error),
                      ].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final m = entry.value;
                        final (val, label, icon, color) = m;
                        final isSel = _selectedStatus == val;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: idx == 0 ? 0 : 6,
                              right: idx == 1 ? 0 : 6,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedStatus = val;
                                  if (val != 'unpaid') {
                                    _reasonError = null;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? color.withOpacity(0.1)
                                      : AppColors.surfaceVariant,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel
                                        ? color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon,
                                        color: isSel
                                            ? color
                                            : AppColors.textMuted,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text(label,
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: isSel
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSel
                                                ? color
                                                : AppColors
                                                    .textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (isUnpaid) ...[
                      const SizedBox(height: 12),
                      Text('Lý do không thanh toán:',
                          style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonController,
                        onChanged: (val) {
                          if (val.trim().isNotEmpty && _reasonError != null) {
                            setState(() {
                              _reasonError = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do (khuyến mãi 100% hóa đơn)...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                          errorText: _reasonError,
                          errorStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final container = ProviderScope.containerOf(context);
                      showDialog(
                        context: context,
                        builder: (_) => UncontrolledProviderScope(
                          container: container,
                          child: InvoicePrintPreviewDialog(
                            tableName: widget.tableName,
                            startTime: widget.startTime,
                            endTime: widget.endTime,
                            playMinutes: widget.playMinutes,
                            playAmount: widget.playAmount,
                            hourlyRate: widget.hourlyRate,
                            products: widget.products,
                            totalAmount: widget.totalAmount,
                            discountPercent: currentDiscountPercent,
                            discountAmount: currentDiscountAmount,
                            netTotal: currentNetTotal,
                            member: widget.member,
                            cashierName: cashierName,
                            shiftLabel: activeShift != null
                                ? 'Ca ${activeShift.id.replaceAll('shift-', '')}'
                                : null,
                            status: _selectedStatus,
                            note: _selectedStatus == 'unpaid' &&
                                    _reasonController.text.trim().isNotEmpty
                                ? _reasonController.text.trim()
                                : widget.note,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const Text('In hóa đơn'),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            if (_selectedStatus == 'unpaid' && _reasonController.text.trim().isEmpty) {
                              setState(() {
                                _reasonError = 'Vui lòng nhập lý do không thanh toán';
                              });
                              return;
                            }
                            final navigator = Navigator.of(context);
                            setState(() => _isProcessing = true);
                            try {
                              await widget.onConfirm(
                                status: _selectedStatus,
                                paymentMethod: _selectedStatus == 'unpaid' ? null : 'cash',
                                discountAmount: currentDiscountAmount,
                                netTotal: currentNetTotal,
                                note: _selectedStatus == 'unpaid'
                                    ? (widget.note != null && widget.note!.isNotEmpty
                                        ? '${widget.note}\nLý do: ${_reasonController.text.trim()}'
                                        : 'Lý do: ${_reasonController.text.trim()}')
                                    : widget.note,
                              );
                              // Chỉ đóng dialog khi onConfirm thành công
                              if (navigator.mounted) {
                                navigator.pop();
                              }
                            } catch (e) {
                              // onConfirm đã hiện SnackBar lỗi — giữ dialog mở để user thử lại
                            } finally {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                          },
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.check_circle_outlined,
                            size: 16),
                    label: Text(_isProcessing
                        ? 'Đang xử lý...'
                        : 'Xác nhận thanh toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500)),
        ]),
      );
}
