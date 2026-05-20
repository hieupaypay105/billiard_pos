import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

InputDecoration khHangInputDecoration({required String hintText}) {
  return InputDecoration(
    isDense: true,
    hintText: hintText,
    hintStyle: const TextStyle(
      fontSize: 16,
      color: Color(0x80B9B0AC), // rgba(185,176,172,0.5)
      fontWeight: FontWeight.w400,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    filled: true,
    fillColor: const Color(0x33FAF2EF), // rgba(250,242,239,0.2)
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryGold),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}

Widget khHangFieldColumn({
  required String label,
  required Widget child,
  bool required = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      khHangLabel(label, required: required),
      const SizedBox(height: 6),
      child,
    ],
  );
}

Widget khHangFieldRow({required Widget left, required Widget right}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    ),
  );
}

Widget khHangLabel(String text, {bool required = false}) {
  if (!required) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: Color(0xFF645E5A),
      ),
    );
  }
  return Text.rich(
    TextSpan(
      text: '${text.toUpperCase()} ',
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: Color(0xFF645E5A),
      ),
      children: const [
        TextSpan(
          text: '*',
          style: TextStyle(color: Color(0xFFE61B1B)),
        ),
      ],
    ),
  );
}

Widget khHangFormTextField({
  required String name,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  int? maxLines = 1,
  double height = 42,
  List<FormFieldValidator<String>>? validators,
}) {
  return SizedBox(
    height: validators != null && validators.isNotEmpty ? null : height,
    child: FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      maxLines: maxLines,
      expands: maxLines == null,
      textAlignVertical: maxLines == null ? TextAlignVertical.top : null,
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: khHangInputDecoration(hintText: hint),
      validator: validators != null
          ? FormBuilderValidators.compose(validators)
          : null,
    ),
  );
}

Widget khHangFormDropdown<T>({
  required String name,
  required String placeholder,
  required List<DropdownMenuItem<T>> items,
  ValueChanged<T?>? onChanged,
  bool enabled = true,
}) {
  return SizedBox(
    height: 42,
    child: FormBuilderDropdown<T>(
      name: name,
      enabled: enabled,
      dropdownColor: const Color(0xFF322F36),
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: khHangInputDecoration(hintText: '').copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      hint: Text(
        placeholder,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0x80B9B0AC), // rgba(185,176,172,0.5)
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0x80B9B0AC),
        size: 20,
      ),
      items: items,
      onChanged: onChanged,
    ),
  );
}

Widget khHangFormDateField({
  required String name,
  required String hint,
  required BuildContext context,
}) {
  return SizedBox(
    height: 42,
    child: FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.date,
      format: DateFormat('dd/MM/yyyy'),
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: khHangInputDecoration(hintText: hint).copyWith(
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: Color(0x80B9B0AC),
          size: 20,
        ),
      ),
    ),
  );
}

Widget khHangFormMultiSelectSheet<T>({
  required String name,
  required String hintText,
  required Map<T, String> options,
  required BuildContext context,
  bool enabled = true,
  List<T> initialValue = const [],
}) {
  return FormBuilderField<List<T>>(
    name: name,
    enabled: enabled,
    initialValue: initialValue,
    builder: (field) {
      final selected = field.value ?? <T>[];
      final displayText = selected.isEmpty
          ? null
          : selected.map((k) => options[k] ?? k.toString()).join(', ');

      return GestureDetector(
        onTap: enabled
            ? () async {
                final result = await khHangShowMultiSelectSheet<T>(
                  context: context,
                  title: hintText,
                  options: options,
                  selected: selected,
                );
                if (result != null) {
                  field.didChange(result);
                }
              }
            : null,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0x33FAF2EF), // rgba(250,242,239,0.2)
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText ?? hintText,
                  style: TextStyle(
                    fontSize: 16,
                    color: displayText != null
                        ? Colors.white
                        : const Color(0x80B9B0AC),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0x80B9B0AC),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<List<T>?> khHangShowMultiSelectSheet<T>({
  required BuildContext context,
  required String title,
  required Map<T, String> options,
  required List<T> selected,
}) async {
  final tempSelected = List<T>.from(selected);

  return showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(
      0xFF322F36,
    ), // AppColors.filterDropdownPanel equivalent
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setSheetState(tempSelected.clear);
                        },
                        child: const Text(
                          'Bỏ chọn tất cả',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Options list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (_, i) {
                        final entry = options.entries.elementAt(i);
                        final isChecked = tempSelected.contains(entry.key);
                        return CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primaryGold,
                          checkColor: const Color(
                            0xFF2F2A29,
                          ), // AppColors.darkBackground2 equivalent
                          title: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          value: isChecked,
                          onChanged: (checked) {
                            setSheetState(() {
                              if (checked ?? false) {
                                tempSelected.add(entry.key);
                              } else {
                                tempSelected.remove(entry.key);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(tempSelected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
