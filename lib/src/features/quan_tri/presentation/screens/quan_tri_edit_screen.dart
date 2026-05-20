import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/quan_tri/domain/entities/quan_tri_item.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QuanTriEditScreen extends StatefulWidget {
  const QuanTriEditScreen({required this.item, super.key});

  final QuanTriItem item;

  @override
  State<QuanTriEditScreen> createState() => _QuanTriEditScreenState();
}

class _QuanTriEditScreenState extends State<QuanTriEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const _fFullname = 'fullname';
  static const _fEmployeeCode = 'employee_code';
  static const _fUsername = 'username';
  static const _fMobile = 'mobile';
  static const _fEmail = 'email';
  static const _fRoleName = 'role_name';
  static const _fStatus = 'status';

  bool _isSubmitting = false;

  Future<void> _onDone() async {
    _formKey.currentState?.save();

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<QuanTriProvider>();
    final formData = _formKey.currentState!.value;

    final statusText = (formData[_fStatus] as String?) ?? '';
    final statusValue = statusText == 'Kích hoạt' ? '1' : '0';

    final data = <String, dynamic>{
      'id': widget.item.id,
      'fullname': (formData[_fFullname] as String?)?.trim() ?? '',
      'employee_code': (formData[_fEmployeeCode] as String?)?.trim() ?? '',
      'username': (formData[_fUsername] as String?)?.trim() ?? '',
      'mobile': (formData[_fMobile] as String?)?.trim() ?? '',
      'email': (formData[_fEmail] as String?)?.trim() ?? '',
      'role_name': (formData[_fRoleName] as String?)?.trim() ?? '',
      'status': statusValue,
    };

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
      } else if (provider.submitError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.submitError!),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialStatusText = widget.item.status == '1'
        ? 'Kích hoạt'
        : 'Chưa kích hoạt';

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
                            _fFullname: widget.item.fullname,
                            _fEmployeeCode: widget.item.employeeCode ?? '',
                            _fUsername: widget.item.username,
                            _fMobile: widget.item.mobile,
                            _fEmail: widget.item.email,
                            _fRoleName: widget.item.roleName,
                            _fStatus: initialStatusText,
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Họ và tên'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                name: _fFullname,
                                hint: 'Nhập họ và tên',
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Mã nhân viên'),
                                        const SizedBox(height: 6),
                                        _buildFormTextField(
                                          name: _fEmployeeCode,
                                          hint: 'Mã nhân viên',
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
                                        _buildLabel('Tên đăng nhập'),
                                        const SizedBox(height: 6),
                                        _buildFormTextField(
                                          name: _fUsername,
                                          hint: 'Tên đăng nhập',
                                          readOnly: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Số điện thoại'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                name: _fMobile,
                                hint: 'Số điện thoại',
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 14),
                              _buildLabel('Email'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                name: _fEmail,
                                hint: 'Email',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Nhóm quyền'),
                                        const SizedBox(height: 6),
                                        _buildFormDropdown(
                                          name: _fRoleName,
                                          placeholder: 'Nhóm quyền',
                                          options: const [
                                            'Nhân viên sale',
                                            'Quản lý',
                                            'Admin',
                                          ],
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
                                        _buildLabel('Tình trạng'),
                                        const SizedBox(height: 6),
                                        _buildFormDropdown(
                                          name: _fStatus,
                                          placeholder: 'Tình trạng',
                                          options: const [
                                            'Kích hoạt',
                                            'Chưa kích hoạt',
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
