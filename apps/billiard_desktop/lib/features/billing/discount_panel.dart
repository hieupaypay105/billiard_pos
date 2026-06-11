import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../tables/tables_provider.dart';

class DiscountPanel extends ConsumerStatefulWidget {
  final String tableId;
  const DiscountPanel({super.key, required this.tableId});

  @override
  ConsumerState<DiscountPanel> createState() => _DiscountPanelState();
}

class _DiscountPanelState extends ConsumerState<DiscountPanel> {
  final _codeCtrl = TextEditingController();
  final _percentCtrl = TextEditingController();
  double _manualPercent = 0;
  bool _isVerifying = false;
  String? _appliedCode;
  String? _errorMsg;

  final _presets = [5.0, 10.0, 15.0, 20.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tablesState = ref.read(tablesProvider);
      double currentDiscount = 0.0;
      if (tablesState.tableDiscounts.containsKey(widget.tableId)) {
        currentDiscount = tablesState.tableDiscounts[widget.tableId] ?? 0.0;
      } else {
        final invIndex = tablesState.unpaidInvoices.indexWhere((inv) => inv.id == widget.tableId);
        if (invIndex >= 0) {
          currentDiscount = tablesState.unpaidInvoices[invIndex].manualDiscountPercent;
        }
      }
      if (currentDiscount > 0) {
        setState(() {
          _manualPercent = currentDiscount;
          _percentCtrl.text = currentDiscount % 1 == 0
              ? currentDiscount.toInt().toString()
              : currentDiscount.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() { _isVerifying = true; _errorMsg = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: BIDA10 = 10% off
    if (_codeCtrl.text.trim().toUpperCase() == 'BIDA10') {
      setState(() { _appliedCode = 'BIDA10 (−10%)'; _manualPercent = 10; });
    } else {
      setState(() => _errorMsg = 'Mã khuyến mãi không hợp lệ');
    }
    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(tablesProvider);
    double currentDiscount = 0.0;
    if (tablesState.tableDiscounts.containsKey(widget.tableId)) {
      currentDiscount = tablesState.tableDiscounts[widget.tableId] ?? 0.0;
    } else {
      final invIndex = tablesState.unpaidInvoices.indexWhere((inv) => inv.id == widget.tableId);
      if (invIndex >= 0) {
        currentDiscount = tablesState.unpaidInvoices[invIndex].manualDiscountPercent;
      }
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.local_offer_outlined, color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Áp dụng khuyến mãi', style: AppTextStyles.headlineSmall, overflow: TextOverflow.ellipsis),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20)),
              ]),
              const SizedBox(height: 20),

              // Promo Code
              Text('Mã khuyến mãi', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã... (ví dụ: BIDA10)',
                      errorText: _errorMsg,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Áp dụng'),
                ),
              ]),
              if (_appliedCode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text('Đã áp dụng: $_appliedCode',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                            color: AppColors.success, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Manual discount
              Text('Giảm giá thủ công (%)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Row(children: _presets.map((pct) {
                final isSel = _manualPercent == pct;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _manualPercent = pct;
                          _percentCtrl.text = pct % 1 == 0 ? pct.toInt().toString() : pct.toString();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent.withOpacity(0.1) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSel ? AppColors.accent : Colors.transparent, width: 2),
                        ),
                        child: Text('${pct.toInt()}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                                color: isSel ? AppColors.accent : AppColors.textSecondary)),
                      ),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 12),
              TextField(
                controller: _percentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Nhập số phần trăm khác...',
                  hintStyle: AppTextStyles.bodySmall,
                  suffixText: '%',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  setState(() {
                    _manualPercent = parsed.clamp(0.0, 100.0);
                  });
                },
              ),

              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.read(tablesProvider.notifier).applyDiscount(widget.tableId, _manualPercent);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _manualPercent > 0
                          ? 'Xác nhận giảm ${_manualPercent.toInt()}%'
                          : 'Xác nhận',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                  if (currentDiscount > 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(tablesProvider.notifier).removeDiscount(widget.tableId);
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Bỏ chiết khấu',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
