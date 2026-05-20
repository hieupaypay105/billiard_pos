import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/core/widgets/an_gradient_border.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CongTacVienAddScreen extends StatefulWidget {
  const CongTacVienAddScreen({super.key});

  @override
  State<CongTacVienAddScreen> createState() => _CongTacVienAddScreenState();
}

class _CongTacVienAddScreenState extends State<CongTacVienAddScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const _fFullname = 'fullname';
  static const _fMobile = 'mobile';
  static const _fCode = 'code';
  static const _fEmail = 'email';
  static const _fStatus = 'status';
  static const _fSaleQl = 'sale_id';

  bool _isGenning = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _genCode() async {
    if (_isGenning) return;

    setState(() => _isGenning = true);

    try {
      final provider = context.read<CongTacVienProvider>();
      final code = await provider.genCode();
      _formKey.currentState?.fields[_fCode]?.didChange(code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenning = false);
    }
  }

  Future<void> _onDone() async {
    _formKey.currentState?.save();

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<CongTacVienProvider>();
    final userProvider = context.read<UserProvider>();

    final formData = _formKey.currentState!.value;

    final statusValue = formData[_fStatus] == true ? '1' : '0';

    final data = <String, dynamic>{
      'parent_id': formData[_fSaleQl] ?? userProvider.currentUser?.id ?? '',
      'email': (formData[_fEmail] as String?)?.trim() ?? '',
      'fullname': (formData[_fFullname] as String?)?.trim() ?? '',
      'code': (formData[_fCode] as String?)?.trim() ?? '',
      'mobile': (formData[_fMobile] as String?)?.trim() ?? '',
      'status': statusValue,
    };

    final success = await provider.createPartner(data: data);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm mới thành công'),
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
    final provider = context.watch<CongTacVienProvider>();
    final options = provider.options;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'THÊM MỚI',
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
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 72 + 37,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dashboardCardBorder),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.dashboardCardStart,
                        AppColors.dashboardCardEnd,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: const {_fStatus: true},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Họ và tên'),
                        _buildFormTextField(
                          name: _fFullname,
                          hint: 'Nhập họ và tên',
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Điện thoại'),
                        _buildFormTextField(
                          name: _fMobile,
                          hint: 'Nhập số điện thoại',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        // Mã đăng nhập + Tạo mã
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Mã đăng nhập'),
                                  _buildFormTextField(
                                    name: _fCode,
                                    hint: 'Mã đăng nhập',
                                    readOnly: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Tạo mã'),
                                  GestureDetector(
                                    onTap: _isGenning ? null : _genCode,
                                    child: AnGradientBorder(
                                      width: double.infinity,
                                      height: 48,
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: _isGenning
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors
                                                          .authButtonText,
                                                    ),
                                              )
                                            : const Text(
                                                'GEN MÃ',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.authButtonText,
                                                  fontSize: 10,
                                                  letterSpacing: 1,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Email'),
                        _buildFormTextField(
                          name: _fEmail,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Sale quản lý'),
                        _buildFormDropdown<String>(
                          name: _fSaleQl,
                          placeholder: provider.isLoadingOptions
                              ? 'Đang tải Sale quản lý'
                              : 'Chọn Sale quản lý',
                          items:
                              options?.sale.entries
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e.key.toString(),
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList() ??
                              [],
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Trạng thái'),
                        const SizedBox(height: 8),
                        FormBuilderSwitch(
                          name: _fStatus,
                          title: const Text(
                            'Hoạt động',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppColors.searchLabel,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.titleGradientStart,
                          activeTrackColor: AppColors.authTextDisabled,
                          inactiveThumbColor: AppColors.authTextDisabled,
                          inactiveTrackColor: AppColors.buttonBgDark,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 48),
                        AnGradientBorder(
                          width: double.infinity,
                          backgroundColor: AppColors.buttonBgDark,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSubmitting ? null : _onDone,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.authButtonText,
                                        ),
                                      )
                                    : const Text(
                                        'XONG',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.authButtonText,
                                          fontSize: 14,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 10,
          letterSpacing: 1,
          color: AppColors.searchLabel,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool readOnly,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: AppColors.authTextSecondary.withOpacity(0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      filled: true,
      fillColor: AppColors.inputFillLight,
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

  Widget _buildFormTextField({
    required String name,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: readOnly ? AppColors.authTextSecondary : Colors.white,
      ),
      decoration: _inputDecoration(hint: hint, readOnly: readOnly),
    );
  }

  Widget _buildFormDropdown<T>({
    required String name,
    required String placeholder,
    required List<DropdownMenuItem<T>> items,
  }) {
    return FormBuilderDropdown<T>(
      name: name,
      dropdownColor: AppColors.filterBg,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: Colors.white,
      ),
      decoration: _inputDecoration(
        hint:
            '', // Provide empty string to prevent floating hintText from overlapping Dropdown hint
        readOnly: false,
      ),
      hint: Text(
        placeholder,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: AppColors.searchIconHint,
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.searchIconHint),
      items: items,
    );
  }
}
