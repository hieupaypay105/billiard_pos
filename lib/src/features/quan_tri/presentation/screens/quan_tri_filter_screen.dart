import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QuanTriFilterScreen extends StatefulWidget {
  const QuanTriFilterScreen({required this.initialFilter, super.key});

  final QuanTriFilter initialFilter;

  @override
  State<QuanTriFilterScreen> createState() => _QuanTriFilterScreenState();
}

class _QuanTriFilterScreenState extends State<QuanTriFilterScreen> {
  final _keywordController = TextEditingController();
  int? _status;
  String? _roleId;

  static const _statusOptions = [
    _FilterOption(label: 'Tất cả', value: null),
    _FilterOption(label: 'Kích hoạt', value: 1),
    _FilterOption(label: 'Không hoạt động', value: 0),
  ];

  static const _roleOptions = [
    _RoleOption(label: 'Tất cả', value: null),
    _RoleOption(label: 'Nhân viên sale', value: 'nhan_vien_sale'),
    _RoleOption(label: 'Quản lý', value: 'quan_ly'),
    _RoleOption(label: 'Admin', value: 'admin'),
  ];

  @override
  void initState() {
    super.initState();
    _keywordController.text = widget.initialFilter.keyword ?? '';
    _status = widget.initialFilter.status;
    _roleId = widget.initialFilter.roleId;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App bar ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: AnFeatureAppBar(
                  avatarUrl:
                      context.read<UserProvider>().currentUser?.avatar ?? '',
                  featureTitle: 'BỘ LỌC QUẢN TRỊ',
                  onBackTap: () => context.pop(),
                  showNotification: false,
                  showFilter: false,
                  showAdd: false,
                  showSearch: false,
                ),
              ),
              const SizedBox(height: 20),

              // ── Filter Form ─────────────────────────────
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
                        // ── Từ khóa ─────────────────────────────────
                        const Text(
                          'Từ khóa',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 36,
                          child: FormBuilderTextField(
                            name: 'keyword',
                            controller: _keywordController,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Nhập từ khóa',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFCFAF4),
                              suffixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: AppColors.textHint,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBackgroundSolid,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.cardBackgroundSolid,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Nhóm quyền ──────────────────────────────
                        const Text(
                          'Nhóm quyền',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFAF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cardBackgroundSolid,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _roleId,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textHint,
                              ),
                              hint: const Text(
                                'Nhóm quyền',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                              items: _roleOptions
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
                              onChanged: (newValue) {
                                setState(() => _roleId = newValue);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Tình trạng ──────────────────────────────
                        const Text(
                          'Tình trạng',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFAF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cardBackgroundSolid,
                            ),
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
                                'Tình trạng',
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
                        const SizedBox(height: 24),

                        // ── Xong button ─────────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }

  void _onDone() {
    context.pop(
      QuanTriFilter(
        keyword: _keywordController.text.trim().isEmpty
            ? null
            : _keywordController.text.trim(),
        status: _status,
        roleId: _roleId,
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.label, required this.value});

  final String label;
  final int? value;
}

class _RoleOption {
  const _RoleOption({required this.label, required this.value});

  final String label;
  final String? value;
}
