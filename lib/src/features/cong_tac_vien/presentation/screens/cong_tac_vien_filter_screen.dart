import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/core/widgets/an_gradient_border.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CongTacVienFilterScreen extends StatefulWidget {
  const CongTacVienFilterScreen({required this.initialFilter, super.key});

  final CongTacVienFilter initialFilter;

  @override
  State<CongTacVienFilterScreen> createState() =>
      _CongTacVienFilterScreenState();
}

class _CongTacVienFilterScreenState extends State<CongTacVienFilterScreen> {
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'TÌM KIẾM',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.dashboard);
          }
        },
        onNotificationTap: () async {
          await context.push(RoutePaths.notification);
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 37, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // ── Tình trạng ──
                Text(
                  'TÌNH TRẠNG',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.searchLabel,
                    letterSpacing: 1,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.inputFillLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _status,
                      isExpanded: true,
                      dropdownColor: AppColors.darkBackground2,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.authTextSecondary,
                        size: 24,
                      ),
                      hint: Text(
                        'Chọn tình trạng',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 16,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      items: _statusOptions
                          .map(
                            (option) => DropdownMenuItem<int?>(
                              value: option.value,
                              child: Text(
                                option.label,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 16,
                                  color: AppColors.authTextSecondary,
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
                const SizedBox(height: 24),

                // ── Sale quản lý ──
                Text(
                  'SALE QUẢN LÝ',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.searchLabel,
                    letterSpacing: 1,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.inputFillLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedSaleId,
                      isExpanded: true,
                      dropdownColor: AppColors.darkBackground2,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.authTextSecondary,
                        size: 24,
                      ),
                      hint: Text(
                        provider.isLoadingOptions
                            ? 'Đang tải Sale QL'
                            : 'Chọn sale quản lý',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 16,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      items: saleOptions
                          .map(
                            (option) => DropdownMenuItem<String?>(
                              value: option.value,
                              child: Text(
                                option.label,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 16,
                                  color: AppColors.authTextSecondary,
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
                const SizedBox(height: 32),

                // ── Xong button ──
                Center(
                  child: AnGradientBorder(
                    width: 196,
                    backgroundColor: AppColors.buttonBgDark,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: InkWell(
                      onTap: _onDone,
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: Text(
                          'XONG',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.authButtonText,
                            letterSpacing: 2.8,
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
    context.pop(
      CongTacVienFilter(
        keyword: widget.initialFilter.keyword,
        status: _status,
        saleId: _saleId,
        page: widget.initialFilter.page,
        perPage: widget.initialFilter.perPage,
        sortBy: widget.initialFilter.sortBy,
        order: widget.initialFilter.order,
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
