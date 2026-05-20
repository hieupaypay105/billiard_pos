import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class KhachHangSaleDialog extends StatefulWidget {
  const KhachHangSaleDialog({
    required this.options,
    required this.selected,
    super.key,
  });

  final Map<int, String> options;
  final List<int> selected;

  @override
  State<KhachHangSaleDialog> createState() => _KhachHangSaleDialogState();
}

class _KhachHangSaleDialogState extends State<KhachHangSaleDialog> {
  late List<int> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List<int>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF322F36), // Updated for dark theme
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Chọn Sale phụ trách',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.options.entries.map((e) {
            final isSelected = _tempSelected.contains(e.key);
            return CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                e.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              value: isSelected,
              activeColor: AppColors.primaryGold,
              checkColor: Colors.white,
              side: const BorderSide(color: Color(0x80B9B0AC)), // dim border
              onChanged: (checked) {
                setState(() {
                  if (checked ?? false) {
                    _tempSelected.add(e.key);
                  } else {
                    _tempSelected.remove(e.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Hủy',
            style: TextStyle(color: Color(0xFFB9B0AC)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _tempSelected),
          child: const Text(
            'Xong',
            style: TextStyle(
              color: AppColors.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
