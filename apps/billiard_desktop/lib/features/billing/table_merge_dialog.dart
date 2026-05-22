import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../tables/tables_provider.dart';

class TableMergeDialog extends ConsumerWidget {
  final String sourceTableId;
  const TableMergeDialog({super.key, required this.sourceTableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesState = ref.watch(tablesProvider);
    final activeTables = tablesState.tables
        .where((t) => t.status == 'active' && t.id != sourceTableId)
        .toList();
    final sourceTable =
        tablesState.tables.firstWhere((t) => t.id == sourceTableId);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.merge_type, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Gộp bàn', style: AppTextStyles.headlineSmall),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Gộp hóa đơn của ${sourceTable.tableName} sang bàn khác đang hoạt động.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (activeTables.isEmpty) ...[
                Center(child: Column(children: [
                  const Icon(Icons.table_bar_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('Không có bàn nào khác đang hoạt động',
                      style: AppTextStyles.bodySmall),
                ])),
              ] else ...[
                Text('Chọn bàn đích để gộp vào:', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),
                ...activeTables.map((t) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tableActive,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.table_bar,
                            color: AppColors.tableActiveAccent, size: 20),
                      ),
                      title: Text(t.tableName, style: AppTextStyles.titleMedium),
                      subtitle: Text(
                          '${(tablesState.tableOrders[t.id] ?? []).length} sản phẩm',
                          style: AppTextStyles.labelSmall),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(tablesProvider.notifier)
                              .mergeTable(sourceTableId, t.id);
                          if (success) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Đã gộp ${sourceTable.tableName} → ${t.tableName}'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Gộp bàn thất bại!'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Gộp'),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      tileColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    )),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class TableTransferDialog extends ConsumerWidget {
  final String sourceTableId;
  const TableTransferDialog({super.key, required this.sourceTableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesState = ref.watch(tablesProvider);
    final idleTables = tablesState.tables
        .where((t) => t.status == 'idle' && t.id != sourceTableId)
        .toList();
    final sourceTable =
        tablesState.tables.firstWhere((t) => t.id == sourceTableId);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Chuyển bàn', style: AppTextStyles.headlineSmall),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Chuyển khách từ ${sourceTable.tableName} sang bàn trống khác.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (idleTables.isEmpty) ...[
                Center(child: Column(children: [
                  const Icon(Icons.table_bar_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('Không có bàn trống nào', style: AppTextStyles.bodySmall),
                ])),
              ] else ...[
                Text('Chọn bàn muốn chuyển đến:', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),
                ...idleTables.map((t) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.table_bar,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      title: Text(t.tableName, style: AppTextStyles.titleMedium),
                      subtitle: Text('Trống', style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.success)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final success = await ref
                              .read(tablesProvider.notifier)
                              .transferTable(sourceTableId, t.id);
                          if (success) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Đã chuyển ${sourceTable.tableName} → ${t.tableName}'),
                                backgroundColor: AppColors.info,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Chuyển bàn thất bại!'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Chuyển'),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      tileColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    )),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
