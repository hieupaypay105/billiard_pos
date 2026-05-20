import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:flutter/material.dart';

class DuAnFilterSheet extends StatefulWidget {
  const DuAnFilterSheet({
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final DuAnFilter initialFilter;
  final ValueChanged<DuAnFilter> onApply;

  @override
  State<DuAnFilterSheet> createState() => _DuAnFilterSheetState();
}

class _DuAnFilterSheetState extends State<DuAnFilterSheet> {
  int? _status;
  String? _projectType;

  static const List<_FilterOption<int?>> _statusOptions = [
    _FilterOption(label: 'Tất cả', value: null),
    _FilterOption(label: 'Hoạt động', value: 1),
    _FilterOption(label: 'Không hoạt động', value: 0),
  ];

  static const List<_FilterOption<String?>> _projectTypeOptions = [
    _FilterOption(label: 'Tất cả', value: null),
    _FilterOption(label: 'Chuyển nhượng', value: 'CN'),
    _FilterOption(label: 'Chủ đầu tư', value: 'CDT'),
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
    _projectType = widget.initialFilter.projectType;
  }

  @override
  Widget build(BuildContext context) {
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
                _buildLabel('Tình trạng'),
                const SizedBox(height: 6),
                _buildDropdown<int?>(
                  value: _status,
                  hint: 'Hoạt động',
                  options: _statusOptions,
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 24),

                // Loại dự án
                _buildLabel('Loại dự án'),
                const SizedBox(height: 6),
                _buildDropdown<String?>(
                  value: _projectType,
                  hint: 'Chuyển nhượng',
                  options: _projectTypeOptions,
                  onChanged: (value) => setState(() => _projectType = value),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<_FilterOption<T>> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBackgroundSolid),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textHint,
          ),
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
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
    );
  }

  void _onDone() {
    widget.onApply(
      DuAnFilter(
        status: _status,
        projectType: _projectType,
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final T? value;
}
