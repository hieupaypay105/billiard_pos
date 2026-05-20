import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/provider/bang_hang_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const Color _kBgTop = AppColors.dashboardBgStart;
const Color _kBgBottom = AppColors.dashboardBgEnd;

class BangHangColumnSettingsScreen extends StatelessWidget {
  const BangHangColumnSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgTop,
      appBar: AnFeatureAppBar(
        featureTitle: 'HIỂN THỊ',
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBgTop, _kBgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),


              // ── Settings Content ─────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Consumer<BangHangProvider>(
                    builder: (_, provider, _) {
                      // Filter columns that actually exist or maintain the order.
                      final columnKeys = provider.columnOrder;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24201E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsRow(
                              index: 1, // Start with false/true pattern
                              label: 'Chọn tất cả',
                              checked: provider.allColumnsSelected,
                              onChanged: (checked) =>
                                  provider.toggleAllColumns(checked ?? false),
                            ),
                            ...columnKeys.asMap().entries.map((entry) {
                              final index = entry.key; // 0, 1, 2...
                              final key = entry.value;
                              return _SettingsRow(
                                index: index % 2 == 0
                                    ? 0
                                    : 1, // Alternates 0 and 1
                                label:
                                    provider.columnLabels[key] ?? key,
                                checked: provider.visibleColumns[key] ?? false,
                                onChanged: (_) => provider.toggleColumn(key),
                              );
                            }),
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
    required this.index,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final int index;
  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Alternating backgrounds matching Figma Node 378:3188
    final bgColor = index == 0 ? const Color(0x33B9B0AC) : Colors.transparent;

    return Container(
      height: 48, // Standard touch target height
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () => onChanged(!checked),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: checked,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: Color(0xFFB9B0AC), width: 1.5),
                activeColor: AppColors.primaryGold,
                checkColor: const Color(0xFF24201E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFB9B0AC),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
