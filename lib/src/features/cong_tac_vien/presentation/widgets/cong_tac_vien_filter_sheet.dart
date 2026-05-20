import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CongTacVienFilterSheet extends StatefulWidget {
  const CongTacVienFilterSheet({
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final CongTacVienFilter initialFilter;
  final ValueChanged<CongTacVienFilter> onApply;

  @override
  State<CongTacVienFilterSheet> createState() => _CongTacVienFilterSheetState();
}

class _CongTacVienFilterSheetState extends State<CongTacVienFilterSheet> {
  int? _status;
  String? _saleId;

  static const _statusOptions = [
    _StatusOption(label: 'Tất cả', value: null),
    _StatusOption(label: 'Hoạt động', value: 1),
    _StatusOption(label: 'Không hoạt động', value: 0),
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
    _saleId = widget.initialFilter.saleId;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CongTacVienProvider>();
    final options = provider.options;
    final saleOptions = <_SaleOption>[
      const _SaleOption(label: 'Tất cả', value: null),
    ];
    if (options != null) {
      options.sale.forEach((key, value) {
        saleOptions.add(_SaleOption(label: value, value: key.toString()));
      });
    }
    final selectedSaleId = saleOptions.any((option) => option.value == _saleId)
        ? _saleId
        : null;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundSolid,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tình trạng',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFAF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBackgroundSolid),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _status,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textHint,
                      ),
                      hint: const Text(
                        'Chọn tình trạng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                      items: _statusOptions
                          .map(
                            (option) => DropdownMenuItem<int?>(
                              value: option.value,
                              child: Text(
                                option.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() => _status = newValue);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sale QL',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFAF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBackgroundSolid),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedSaleId,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textHint,
                      ),
                      hint: Text(
                        provider.isLoadingOptions
                            ? 'Đang tải Sale QL'
                            : 'Chọn Sale QL',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                      items: saleOptions
                          .map(
                            (option) => DropdownMenuItem<String?>(
                              value: option.value,
                              child: Text(
                                option.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: provider.isLoadingOptions
                          ? null
                          : (newValue) {
                              setState(() => _saleId = newValue);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  child: SizedBox(
                    width: 161,
                    height: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.buttonGradientStart,
                            AppColors.buttonGradientEnd,
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _onDone,
                          borderRadius: BorderRadius.circular(24),
                          child: const Center(
                            child: Text(
                              'Xong',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.buttonText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDone() {
    widget.onApply(
      CongTacVienFilter(
        status: _status,
        saleId: _saleId,
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption({required this.label, required this.value});

  final String label;
  final int? value;
}

class _SaleOption {
  const _SaleOption({required this.label, required this.value});

  final String label;
  final String? value;
}
