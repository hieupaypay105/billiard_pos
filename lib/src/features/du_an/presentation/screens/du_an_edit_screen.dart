import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/du_an/domain/entities/du_an_item.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DuAnEditScreen extends StatefulWidget {
  const DuAnEditScreen({required this.item, super.key});

  final DuAnItem item;

  @override
  State<DuAnEditScreen> createState() => _DuAnEditScreenState();
}

class _DuAnEditScreenState extends State<DuAnEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const _fName = 'name';
  static const _fAddress = 'address';
  static const _fInvestor = 'investor';
  static const _fHotline = 'hotline';
  static const _fType = 'type';
  static const _fStatus = 'status';
  static const _fNote = 'note';

  bool _isSubmitting = false;

  Future<void> _onDone() async {
    _formKey.currentState?.save();

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<DuAnProvider>();

    final formData = _formKey.currentState!.value;

    final statusText = (formData[_fStatus] as String?) ?? '';
    final statusValue = statusText == 'Không hoạt động' ? '0' : '1';

    final typeText = (formData[_fType] as String?) ?? '';
    final typeValue = switch (typeText) {
      'Chuyển nhượng' => 'CN',
      'Chủ đầu tư' => 'CDT',
      _ => typeText,
    };

    final data = <String, dynamic>{
      'id': widget.item.id,
      'name': (formData[_fName] as String?)?.trim() ?? '',
      'address': (formData[_fAddress] as String?)?.trim() ?? '',
      'investor': (formData[_fInvestor] as String?)?.trim() ?? '',
      'hotline': (formData[_fHotline] as String?)?.trim() ?? '',
      'status': statusValue,
      'type': typeValue,
    };

    final note = (formData[_fNote] as String?)?.trim() ?? '';
    if (note.isNotEmpty) {
      data['note'] = note;
    }

    final success = await provider.updateItem(data: data);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thành công'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final fieldErrors = provider.submitFieldErrors;
      if (fieldErrors != null && fieldErrors.isNotEmpty) {
        final firstErrorField = fieldErrors.entries.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstErrorField.value.first),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.submitError ?? 'Cập nhật thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialStatusText =
        widget.item.status == '1' || widget.item.statusLabel == 'Đang hoạt động'
        ? 'Đang hoạt động'
        : 'Không hoạt động';

    final initialTypeText = switch (widget.item.projectType) {
      'CN' => 'Chuyển nhượng',
      'CDT' => 'Chủ đầu tư',
      _ => widget.item.projectType,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'CẬP NHẬT',
        avatarUrl: context.read<UserProvider>().currentUser?.avatar ?? '',
        onBackTap: () => context.pop(),
        showNotification: false,
        showFilter: false,
        showAdd: false,
        showSearch: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 72 + 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
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
                        FormBuilder(
                          key: _formKey,
                          initialValue: {
                            _fName: widget.item.name,
                            _fAddress: widget.item.address,
                            _fInvestor: widget.item.investor,
                            _fHotline: widget.item.hotline,
                            _fType: initialTypeText,
                            _fStatus: initialStatusText,
                            _fNote: widget.item.note,
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Họ và tên'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                name: _fName,
                                hint: 'Nhập họ và tên',
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Vị trí dự án'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                name: _fAddress,
                                hint: 'Vị trí dự án',
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Nhà đầu tư'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                name: _fInvestor,
                                hint: 'Nhà đầu tư',
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Hotline'),
                                        const SizedBox(height: 6),
                                        _buildFormTextField(
                                          name: _fHotline,
                                          hint: 'Hotline',
                                          keyboardType: TextInputType.phone,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Loại dự án'),
                                        const SizedBox(height: 6),
                                        _buildFormDropdown(
                                          name: _fType,
                                          placeholder: 'Loại dự án',
                                          options: const [
                                            'Chuyển nhượng',
                                            'Chủ đầu tư',
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Tình trạng'),
                              const SizedBox(height: 6),
                              _buildFormDropdown(
                                name: _fStatus,
                                placeholder: 'Tình trạng',
                                options: const [
                                  'Đang hoạt động',
                                  'Không hoạt động',
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Ghi chú'),
                              const SizedBox(height: 6),
                              _buildFormMultilineTextField(
                                name: _fNote,
                                hint: 'Ghi chú',
                              ),
                            ],
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
                                gradient: _isSubmitting
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.buttonGradientStart
                                              .withValues(alpha: 0.5),
                                          AppColors.buttonGradientEnd
                                              .withValues(alpha: 0.5),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          AppColors.buttonGradientStart,
                                          AppColors.buttonGradientEnd,
                                        ],
                                      ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSubmitting ? null : _onDone,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Center(
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.buttonText,
                                            ),
                                          )
                                        : const Text(
                                            'Cập nhật',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool readOnly,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      filled: true,
      fillColor: readOnly ? const Color(0xFFF0EDE5) : const Color(0xFFFCFAF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBackgroundSolid),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBackgroundSolid),
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

  Widget _buildFormTextField({
    required String name,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return SizedBox(
      height: 36,
      child: FormBuilderTextField(
        name: name,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        decoration: _inputDecoration(hint: hint, readOnly: readOnly),
      ),
    );
  }

  Widget _buildFormMultilineTextField({
    required String name,
    required String hint,
  }) {
    return SizedBox(
      height: 108,
      child: FormBuilderTextField(
        name: name,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        decoration: _inputDecoration(hint: hint, readOnly: false),
      ),
    );
  }

  Widget _buildFormDropdown({
    required String name,
    required String placeholder,
    required List<String> options,
  }) {
    return SizedBox(
      height: 36,
      child: FormBuilderDropdown<String>(
        padding: const EdgeInsets.symmetric(vertical: 10),
        name: name,
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        decoration: _inputDecoration(hint: '', readOnly: false).copyWith(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        hint: Padding(
          padding: EdgeInsets.zero,
          child: Text(
            placeholder,
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: AppColors.textHint,
        ),
        iconSize: 20,
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
