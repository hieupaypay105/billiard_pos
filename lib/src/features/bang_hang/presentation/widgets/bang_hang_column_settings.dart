import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BangHangColumnSettings extends StatelessWidget {
  const BangHangColumnSettings({
    required this.columns,
    required this.visibleColumns,
    required this.allSelected,
    required this.onToggleColumn,
    required this.onToggleAll,
    required this.onClose,
    super.key,
  });

  final List<MapEntry<String, String>> columns;
  final Map<String, bool> visibleColumns;
  final bool allSelected;
  final ValueChanged<String> onToggleColumn;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundSolid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cai dat hien thi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.textHint,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsRow(
              label: 'Chon tat ca',
              checked: allSelected,
              onChanged: (checked) => onToggleAll(checked ?? false),
            ),
            const SizedBox(height: 2),
            ...columns.map(
              (column) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _SettingsRow(
                  label: column.value,
                  checked: visibleColumns[column.key] ?? false,
                  onChanged: (_) => onToggleColumn(column.key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: double.infinity,
      color: checked ? const Color(0xFFDFDFDF) : const Color(0xFFFCFAF4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Checkbox(
              value: checked,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: AppColors.borderInactive),
              activeColor: Colors.white,
              checkColor: const Color(0xFF4D8DFF),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
