import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../tables/tables_provider.dart';

class TableMergeDialog extends ConsumerWidget {
  final String? sourceTableId;
  final String? sourceInvoiceId;
  const TableMergeDialog({
    super.key,
    this.sourceTableId,
    this.sourceInvoiceId,
  }) : assert(sourceTableId != null || sourceInvoiceId != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesState = ref.watch(tablesProvider);
    final activeTables = tablesState.tables
        .where((t) => t.status == 'active' && (sourceTableId == null || t.id != sourceTableId))
        .toList();
    final String sourceName = sourceInvoiceId != null
        ? (tablesState.unpaidInvoices.any((inv) => inv.id == sourceInvoiceId)
            ? tablesState.unpaidInvoices.firstWhere((inv) => inv.id == sourceInvoiceId).tableName
            : 'Hóa đơn chờ')
        : (tablesState.tables.any((t) => t.id == sourceTableId)
            ? tablesState.tables.firstWhere((t) => t.id == sourceTableId).tableName
            : 'Bàn');

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
                'Gộp hóa đơn của $sourceName sang bàn khác đang hoạt động.',
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
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final success = sourceInvoiceId != null
                              ? await ref
                                  .read(tablesProvider.notifier)
                                  .mergeUnpaidInvoiceToTable(sourceInvoiceId!, t.id)
                              : await ref
                                  .read(tablesProvider.notifier)
                                  .mergeTable(sourceTableId!, t.id);
                          if (success) {
                            if (navigator.mounted) {
                              navigator.pop();
                            }
                            messenger.showSnackBar(SnackBar(
                              content: Text(
                                  'Đã gộp $sourceName → ${t.tableName}'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ));
                          } else {
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Gộp bàn thất bại!'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ));
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
  final String? sourceTableId;
  final String? sourceInvoiceId;
  const TableTransferDialog({
    super.key,
    this.sourceTableId,
    this.sourceInvoiceId,
  }) : assert(sourceTableId != null || sourceInvoiceId != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesState = ref.watch(tablesProvider);
    final idleTables = tablesState.tables
        .where((t) => t.status == 'idle' && (sourceTableId == null || t.id != sourceTableId))
        .toList();
    final String sourceName = sourceInvoiceId != null
        ? (tablesState.unpaidInvoices.any((inv) => inv.id == sourceInvoiceId)
            ? tablesState.unpaidInvoices.firstWhere((inv) => inv.id == sourceInvoiceId).tableName
            : 'Hóa đơn chờ')
        : (tablesState.tables.any((t) => t.id == sourceTableId)
            ? tablesState.tables.firstWhere((t) => t.id == sourceTableId).tableName
            : 'Bàn');

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
                'Chuyển khách từ $sourceName sang bàn trống khác.',
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
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final notifier = ref.read(tablesProvider.notifier);
                          final success = sourceInvoiceId != null
                              ? await notifier.transferUnpaidInvoiceToTable(sourceInvoiceId!, t.id)
                              : await notifier.transferTable(sourceTableId!, t.id);
                          if (success) {
                            if (navigator.mounted) {
                              navigator.pop();
                            }
                            messenger.showSnackBar(SnackBar(
                              content: Text(
                                  'Đã chuyển $sourceName → ${t.tableName}'),
                              backgroundColor: AppColors.info,
                              behavior: SnackBarBehavior.floating,
                            ));
                          } else {
                            if (navigator.mounted) {
                              if (sourceInvoiceId != null) {
                                final force = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: AppColors.error),
                                        SizedBox(width: 8),
                                        Text('Lỗi kết nối IoT'),
                                      ],
                                    ),
                                    content: const Text(
                                      'Không thể kết nối đến Relay IoT cho bàn trống này.\n'
                                      'Bạn có muốn bật bàn thủ công (không sử dụng IoT rơ-le) để tiếp tục chuyển hóa đơn không?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                        child: const Text('Bật thủ công'),
                                      ),
                                    ],
                                  ),
                                );
                                if (force == true && navigator.mounted) {
                                  final forceOk = await notifier.transferUnpaidInvoiceToTable(sourceInvoiceId!, t.id, ignoreIotError: true);
                                  if (forceOk && navigator.mounted) {
                                    navigator.pop();
                                    messenger.showSnackBar(SnackBar(
                                      content: Text('Đã chuyển $sourceName → ${t.tableName} thủ công'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                    return;
                                  }
                                }
                              }
                              messenger.showSnackBar(const SnackBar(
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
