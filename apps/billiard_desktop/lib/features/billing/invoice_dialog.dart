import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

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

  @override
  Widget build(BuildContext context) {
    final isUnpaid = _selectedStatus == 'unpaid';
    final currentDiscountPercent = isUnpaid ? 100.0 : widget.discountPercent;
    final currentDiscountAmount = isUnpaid ? widget.totalAmount : widget.discountAmount;
    final currentNetTotal = isUnpaid ? 0.0 : widget.netTotal;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 24),
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
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          widget.tableName,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Time info
                    _InfoRow(
                        'Giờ vào',
                        _fmtTime(widget.startTime),
                        Icons.play_circle_outline),
                    _InfoRow(
                        'Giờ ra',
                        _fmtTime(widget.endTime),
                        Icons.stop_circle_outlined),
                    _InfoRow(
                        'Tổng thời gian',
                        '${widget.playMinutes} phút',
                        Icons.timer_outlined),
                    _InfoRow(
                        'Đơn giá',
                        '${_fmtCurrency(widget.hourlyRate)}/giờ',
                        Icons.attach_money),
                    if (widget.member != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: AppColors.success, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thành viên: ${widget.member!['full_name']} (${widget.member!['tier']})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Play amount box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text('Tiền giờ chơi:',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14)),
                          const Spacer(),
                          Text(_fmtCurrency(widget.playAmount),
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),

                    // Products
                    if (widget.products.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Dịch vụ đi kèm:',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      ...widget.products.map((p) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Text(
                                  '${p['name']} × ${p['qty']}',
                                  style: AppTextStyles.bodySmall),
                              const Spacer(),
                              Text(
                                _fmtCurrency(
                                    (p['price'] as double) *
                                        (p['qty'] as int)),
                                style: AppTextStyles.labelLarge,
                              ),
                            ]),
                          )),
                    ],

                    const Divider(height: 24),
                    if (currentDiscountPercent > 0) ...[
                      Row(children: [
                        const Text('Tạm tính', style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(_fmtCurrency(widget.totalAmount),
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('Chiết khấu (${currentDiscountPercent.toInt()}%)', style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.accent)),
                        const Spacer(),
                        Text('-${_fmtCurrency(currentDiscountAmount)}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: AppColors.accent)),
                      ]),
                      const SizedBox(height: 8),
                    ],
                    // Total
                    Row(children: [
                      const Text('TỔNG THANH TOÁN',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const Spacer(),
                      Text(_fmtCurrency(currentNetTotal),
                          style: AppTextStyles.currency),
                    ]),

                    const SizedBox(height: 20),
                    // Payment selector
                    Text('Trạng thái hóa đơn:',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ('paid', 'Thanh toán', Icons.check_circle_rounded,
                            AppColors.primary),
                        ('unpaid', 'Không thanh toán', Icons.money_off_rounded,
                            AppColors.error),
                      ].map((m) {
                        final (val, label, icon, color) = m;
                        final isSel = _selectedStatus == val;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedStatus = val;
                                  if (val != 'unpaid') {
                                    _reasonError = null;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? color.withOpacity(0.1)
                                      : AppColors.surfaceVariant,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(children: [
                                  Icon(icon,
                                      color: isSel
                                          ? color
                                          : AppColors.textMuted,
                                      size: 20),
                                  const SizedBox(height: 4),
                                  Text(label,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: isSel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSel
                                              ? color
                                              : AppColors
                                                  .textSecondary)),
                                ]),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (isUnpaid) ...[
                      const SizedBox(height: 16),
                      Text('Lý do không thanh toán:',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
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
                          hintStyle: AppTextStyles.bodySmall,
                          errorText: _reasonError,
                          errorStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: integrate esc_pos_utils printing
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đang in hóa đơn K80...'),
                              behavior: SnackBarBehavior.floating));
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('In hóa đơn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                                note: _selectedStatus == 'unpaid' ? _reasonController.text.trim() : null,
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                            if (navigator.mounted) {
                              navigator.pop();
                            }
                          },
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.check_circle_outlined,
                            size: 18),
                    label: Text(_isProcessing
                        ? 'Đang xử lý...'
                        : 'Xác nhận thanh toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
