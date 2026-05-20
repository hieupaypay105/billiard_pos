import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/cong_tac_vien/presentation/provider/cong_tac_vien_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CongTacVienColumnSettingsScreen extends StatelessWidget {
  const CongTacVienColumnSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.featureScaffoldStart,
              AppColors.featureScaffoldEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: AnFeatureAppBar(
                  avatarUrl:
                      context.read<UserProvider>().currentUser?.avatar ?? '',
                  featureTitle: 'CÀI ĐẶT HIỂN THỊ',
                  onBackTap: () => context.pop(),
                  showNotification: false,
                  showFilter: false,
                  showAdd: false,
                  showSearch: false,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                  child: Consumer<CongTacVienProvider>(
                    builder: (_, provider, _) {
                      return Container(
                        padding: const EdgeInsets.all(14),
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
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsRow(
                              label: 'Chọn tất cả',
                              checked: provider.allColumnsSelected,
                              onChanged: (checked) =>
                                  provider.toggleAllColumns(checked ?? false),
                            ),
                            const SizedBox(height: 2),
                            ...CongTacVienProvider.columnOrder.map(
                              (key) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: _SettingsRow(
                                  label:
                                      CongTacVienProvider.columnLabels[key] ??
                                      key,
                                  checked:
                                      provider.visibleColumns[key] ?? false,
                                  onChanged: (_) => provider.toggleColumn(key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
