import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KhachHangFilterSheet extends StatefulWidget {
  const KhachHangFilterSheet({
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final KhachHangFilter initialFilter;
  final ValueChanged<KhachHangFilter> onApply;

  @override
  State<KhachHangFilterSheet> createState() => _KhachHangFilterSheetState();
}

class _KhachHangFilterSheetState extends State<KhachHangFilterSheet> {
  int? _status;
  int? _sourceId;
  int? _projectId;
  int? _saleId;

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status.firstOrNull;
    _sourceId = widget.initialFilter.sourceId.firstOrNull;
    _projectId = widget.initialFilter.projectId.firstOrNull;
    _saleId = widget.initialFilter.saleId.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhachHangProvider>();
    final options = provider.options;

    final statusOptions = [const _FilterOption(label: 'Tất cả', value: null)];
    if (options != null) {
      for (var i = 0; i < options.status.length; i++) {
        statusOptions.add(_FilterOption(label: options.status[i], value: i));
      }
    }

    final sourceOptions = [const _FilterOption(label: 'Tất cả', value: null)];
    if (options != null) {
      options.source.forEach((key, value) {
        sourceOptions.add(_FilterOption(label: value, value: key));
      });
    }

    final projectOptions = [const _FilterOption(label: 'Tất cả', value: null)];
    if (options != null) {
      options.project.forEach((key, value) {
        projectOptions.add(_FilterOption(label: value, value: key));
      });
    }

    final saleOptions = [const _FilterOption(label: 'Tất cả', value: null)];
    if (options != null) {
      options.sale.forEach((key, value) {
        saleOptions.add(_FilterOption(label: value, value: key));
      });
    }

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
                // Tình trạng
                _buildFilterField(
                  label: 'Tình trạng',
                  value: _status,
                  placeholder: 'Tình trạng',
                  options: statusOptions,
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 14),

                // Nguồn
                _buildFilterField(
                  label: 'Nguồn',
                  value: _sourceId,
                  placeholder: 'Nguồn',
                  options: sourceOptions,
                  onChanged: (value) => setState(() => _sourceId = value),
                ),
                const SizedBox(height: 14),

                // Dự án
                _buildFilterField(
                  label: 'Dự án',
                  value: _projectId,
                  placeholder: 'Dự án',
                  options: projectOptions,
                  onChanged: (value) => setState(() => _projectId = value),
                ),
                const SizedBox(height: 14),

                // Sale phụ trách
                _buildFilterField(
                  label: 'Sale phụ trách',
                  value: _saleId,
                  placeholder: 'Sale phụ trách',
                  options: saleOptions,
                  onChanged: (value) => setState(() => _saleId = value),
                ),
                const SizedBox(height: 24),

                // Xong button
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

  Widget _buildFilterField({
    required String label,
    required int? value,
    required String placeholder,
    required List<_FilterOption> options,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
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
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textHint,
              ),
              hint: Text(
                placeholder,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDark,
                ),
              ),
              items: options
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
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _onDone() {
    widget.onApply(
      KhachHangFilter(
        status: _status == null ? const [] : [_status!],
        sourceId: _sourceId == null ? const [] : [_sourceId!],
        projectId: _projectId == null ? const [] : [_projectId!],
        saleId: _saleId == null ? const [] : [_saleId!],
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final int? value;
}
