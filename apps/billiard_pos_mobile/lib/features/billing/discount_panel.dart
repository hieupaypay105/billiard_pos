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
  final _playCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _billCtrl = TextEditingController();
  
  double _playPercent = 0.0;
  double _servicePercent = 0.0;
  double _billPercent = 0.0;
  
  bool _isVerifying = false;
  String? _appliedCode;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tablesState = ref.read(tablesProvider);
      double playD = 0.0;
      double serviceD = 0.0;
      double billD = 0.0;
      
      if (tablesState.tablePlayDiscounts.containsKey(widget.tableId)) {
        playD = tablesState.tablePlayDiscounts[widget.tableId] ?? 0.0;
        serviceD = tablesState.tableServiceDiscounts[widget.tableId] ?? 0.0;
        billD = tablesState.tableBillDiscounts[widget.tableId] ?? 0.0;
      } else {
        final invIndex = tablesState.unpaidInvoices.indexWhere((inv) => inv.id == widget.tableId);
        if (invIndex >= 0) {
          final inv = tablesState.unpaidInvoices[invIndex];
          playD = inv.discountPlayPercent;
          serviceD = inv.discountServicePercent;
          billD = inv.discountBillPercent;
        }
      }
      
      setState(() {
        _playPercent = playD;
        _servicePercent = serviceD;
        _billPercent = billD;
        
        _playCtrl.text = playD > 0 ? (playD % 1 == 0 ? playD.toInt().toString() : playD.toString()) : '';
        _serviceCtrl.text = serviceD > 0 ? (serviceD % 1 == 0 ? serviceD.toInt().toString() : serviceD.toString()) : '';
        _billCtrl.text = billD > 0 ? (billD % 1 == 0 ? billD.toInt().toString() : billD.toString()) : '';
      });
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _playCtrl.dispose();
    _serviceCtrl.dispose();
    _billCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() { _isVerifying = true; _errorMsg = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: BIDA10 = 10% off total bill
    if (_codeCtrl.text.trim().toUpperCase() == 'BIDA10') {
      setState(() { 
        _appliedCode = 'BIDA10 (−10% hóa đơn)'; 
        _billPercent = 10; 
        _billCtrl.text = '10';
      });
    } else {
      setState(() => _errorMsg = 'Mã khuyến mãi không hợp lệ');
    }
    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(tablesProvider);
    double currentDiscountPlay = 0.0;
    double currentDiscountService = 0.0;
    double currentDiscountBill = 0.0;
    
    if (tablesState.tablePlayDiscounts.containsKey(widget.tableId)) {
      currentDiscountPlay = tablesState.tablePlayDiscounts[widget.tableId] ?? 0.0;
      currentDiscountService = tablesState.tableServiceDiscounts[widget.tableId] ?? 0.0;
      currentDiscountBill = tablesState.tableBillDiscounts[widget.tableId] ?? 0.0;
    } else {
      final invIndex = tablesState.unpaidInvoices.indexWhere((inv) => inv.id == widget.tableId);
      if (invIndex >= 0) {
        final inv = tablesState.unpaidInvoices[invIndex];
        currentDiscountPlay = inv.discountPlayPercent;
        currentDiscountService = inv.discountServicePercent;
        currentDiscountBill = inv.discountBillPercent;
      }
    }

    final hasActiveDiscount = currentDiscountPlay > 0 || currentDiscountService > 0 || currentDiscountBill > 0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 380,
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
              const SizedBox(height: 16),

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

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Manual discounts
              // 1. Play discount
              Text('Chiết khấu tiền giờ chơi (%)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _playCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Nhập % giảm tiền giờ...',
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
                    _playPercent = parsed.clamp(0.0, 100.0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // 2. Service discount
              Text('Chiết khấu dịch vụ (%)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _serviceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Nhập % giảm tiền dịch vụ...',
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
                    _servicePercent = parsed.clamp(0.0, 100.0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // 3. Bill discount
              Text('Chiết khấu tổng hóa đơn (%)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _billCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Nhập % giảm tổng hóa đơn...',
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
                    _billPercent = parsed.clamp(0.0, 100.0);
                  });
                },
              ),

              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.read(tablesProvider.notifier).applyDiscount(
                        widget.tableId,
                        playPercent: _playPercent,
                        servicePercent: _servicePercent,
                        billPercent: _billPercent,
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                  if (hasActiveDiscount) ...[
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
