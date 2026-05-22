import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../tables/tables_provider.dart';
import 'add_product_panel.dart';
import 'member_lookup.dart';
import 'discount_panel.dart';
import 'invoice_dialog.dart';
import 'table_merge_dialog.dart';
import '../../core/providers/providers.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesState = ref.watch(tablesProvider);
    final activeTables =
        tablesState.tables.where((t) => t.status == 'active').toList();
    final selected = tablesState.selectedTable;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── LEFT: Table selector + Product panel ──────────────────────────
        Expanded(
          flex: 5,
          child: Column(
            children: [
              // Table selector bar
              _TableSelectorBar(activeTables: activeTables),
              // Product grid
              Expanded(
                child: selected != null && selected.status == 'active'
                    ? AddProductPanel(tableId: selected.id)
                    : _NoActiveTablePlaceholder(),
              ),
            ],
          ),
        ),

        // ── RIGHT: Invoice panel ───────────────────────────────────────────
        Container(
          width: 360,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                left: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: selected != null && selected.status == 'active'
              ? _InvoicePanel(
                  table: selected,
                  tablesState: tablesState,
                )
              : _NoActiveTablePlaceholder(),
        ),
      ],
    );
  }
}

// ─── Table Selector Bar ───────────────────────────────────────────────────────

class _TableSelectorBar extends ConsumerWidget {
  final List<TableModel> activeTables;
  const _TableSelectorBar({required this.activeTables});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tablesProvider).selectedTableId;

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('Hóa đơn:', style: AppTextStyles.titleMedium),
          const SizedBox(width: 12),
          if (activeTables.isEmpty)
            Text('Chưa có bàn nào đang mở',
                style: AppTextStyles.bodySmall)
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: activeTables.map((t) {
                    final isActive = t.id == selected;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () =>
                            ref.read(tablesProvider.notifier).selectTable(t.id),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primarySurface
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            t.tableName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Invoice Panel ────────────────────────────────────────────────────────────

class _InvoicePanel extends ConsumerWidget {
  final TableModel table;
  final TablesState tablesState;
  const _InvoicePanel(
      {required this.table, required this.tablesState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = tablesState.tableOrders[table.id] ?? [];
    final startTime =
        tablesState.tableStartTimes[table.id] ?? DateTime.now();
    final rate = tablesState.hourlyRates[table.tableTypeId.toString()] ?? 80000;
    final duration = tablesState.playDuration(table.id);
    final playAmount = tablesState.playCost(table.id);
    double productTotal = products.fold(0.0,
        (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

    final member = tablesState.tableMembers[table.id];
    final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
    final manualDiscountPercent = tablesState.tableDiscounts[table.id] ?? 0.0;
    final discountPercent = (memberDiscountPercent + manualDiscountPercent).clamp(0.0, 100.0);
    
    final discountAmount = (playAmount + productTotal) * (discountPercent / 100.0);
    final netTotal = (playAmount + productTotal) - discountAmount;

    return Column(
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(table.tableName,
                          style: AppTextStyles.headlineSmall)),
                  // Action buttons
                  _ActionButton(
                    icon: Icons.merge_type,
                    label: 'Gộp',
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) =>
                            TableMergeDialog(sourceTableId: table.id)),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Chuyển',
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => TableTransferDialog(
                            sourceTableId: table.id)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Timer display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _fmtDuration(duration),
                      style: AppTextStyles.mono.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      _fmtCurrency(playAmount),
                      style: AppTextStyles.currencySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Active Member/Discount Badge ──
        if (member != null || manualDiscountPercent > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                if (member != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${member['full_name']} (${member['tier']} -${member['discount']}%)',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => ref.read(tablesProvider.notifier).removeMember(table.id),
                          child: const Icon(Icons.cancel, size: 16, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                if (manualDiscountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer, size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Giảm giá KM: -${manualDiscountPercent.toInt()}%',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => ref.read(tablesProvider.notifier).removeDiscount(table.id),
                          child: const Icon(Icons.cancel, size: 16, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const Divider(height: 1),

        // ── Member + Discount Actions ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => MemberLookupDialog(tableId: table.id)),
                  icon: const Icon(Icons.person_search, size: 16),
                  label: const Text('Thành viên'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => DiscountPanel(tableId: table.id)),
                  icon: const Icon(Icons.local_offer_outlined, size: 16),
                  label: const Text('Khuyến mãi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Product list ──
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_outlined,
                          size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Chưa có dịch vụ',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return _ProductLineItem(
                      name: p['name'] as String,
                      qty: p['qty'] as int,
                      price: p['price'] as double,
                      onRemove: () => ref
                          .read(tablesProvider.notifier)
                          .removeProductFromTable(
                              table.id, p['product_id'] as String),
                    );
                  },
                ),
        ),
        const Divider(height: 1),

        // ── Total & Payment ──
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary rows
              _SummaryRow('Tiền giờ chơi', _fmtCurrency(playAmount)),
              _SummaryRow(
                  'Dịch vụ', _fmtCurrency(productTotal)),
              if (discountPercent > 0)
                _SummaryRow(
                  'Chiết khấu (${discountPercent.toInt()}%)',
                  '-${_fmtCurrency(discountAmount)}',
                ),
              const Divider(height: 16),
              Row(
                children: [
                  const Text('TỔNG CỘNG',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  Text(
                    _fmtCurrency(netTotal),
                    style: AppTextStyles.currency,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Payment methods
              Row(
                children: [
                  _PayButton(
                    label: 'Tiền mặt',
                    icon: Icons.money,
                    color: AppColors.cash,
                    onTap: () => _checkout(
                      context,
                      ref,
                      'cash',
                      playAmount,
                      productTotal,
                      discountPercent,
                      discountAmount,
                      netTotal,
                      startTime,
                      products,
                      rate,
                      member,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _PayButton(
                    label: 'Thẻ',
                    icon: Icons.credit_card,
                    color: AppColors.card,
                    onTap: () => _checkout(
                      context,
                      ref,
                      'card',
                      playAmount,
                      productTotal,
                      discountPercent,
                      discountAmount,
                      netTotal,
                      startTime,
                      products,
                      rate,
                      member,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _PayButton(
                    label: 'QR',
                    icon: Icons.qr_code,
                    color: AppColors.transfer,
                    onTap: () => _checkout(
                      context,
                      ref,
                      'transfer',
                      playAmount,
                      productTotal,
                      discountPercent,
                      discountAmount,
                      netTotal,
                      startTime,
                      products,
                      rate,
                      member,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _checkout(
    BuildContext context,
    WidgetRef ref,
    String method,
    double playAmount,
    double productTotal,
    double discountPercent,
    double discountAmount,
    double netTotal,
    DateTime startTime,
    List<Map<String, dynamic>> products,
    double rate,
    Map<String, dynamic>? member,
  ) async {
    final endTime = DateTime.now();
    final playMinutes = endTime.difference(startTime).inMinutes + 1;
    final finalPlayAmount = (playMinutes / 60.0) * rate;
    final finalProductTotal =
        products.fold(0.0, (s, p) => s + (p['price'] as double) * (p['qty'] as int));
    
    // Recalculate based on precise final times at checkout time
    final finalDiscountAmount = (finalPlayAmount + finalProductTotal) * (discountPercent / 100.0);
    final finalNetTotal = (finalPlayAmount + finalProductTotal) - finalDiscountAmount;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => InvoiceDialog(
        tableName: table.tableName,
        startTime: startTime,
        endTime: endTime,
        playMinutes: playMinutes,
        playAmount: finalPlayAmount,
        hourlyRate: rate,
        products: products,
        discountPercent: discountPercent,
        discountAmount: finalDiscountAmount,
        netTotal: finalNetTotal,
        totalAmount: finalPlayAmount + finalProductTotal, // original total before discount
        paymentMethod: method,
        member: member,
        onConfirm: (paymentMethod) async {
          final orderId = table.currentOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';
          
          final orderModel = OrderModel(
            id: orderId,
            tableId: table.id,
            memberId: member?['id']?.toString(),
            shiftId: 'shift-default',
            status: 'paid',
            startTime: startTime,
            endTime: endTime,
            totalPlayTimeMinutes: playMinutes,
            totalPlayTimeAmount: finalPlayAmount,
            totalProductAmount: finalProductTotal,
            discountAmount: finalDiscountAmount,
            taxAmount: 0.0,
            totalAmount: finalNetTotal,
            paymentMethod: paymentMethod,
            createdBy: 'cashier-1',
            closedBy: 'cashier-1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final details = <OrderDetailModel>[];
          for (int i = 0; i < products.length; i++) {
            final p = products[i];
            final pid = p['product_id']?.toString() ?? '';
            final qty = int.tryParse(p['qty']?.toString() ?? '') ?? 1;
            final price = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
            details.add(OrderDetailModel(
              id: 'det-${DateTime.now().millisecondsSinceEpoch}-$pid-$i',
              orderId: orderId,
              productId: pid,
              quantity: qty,
              unitPrice: price,
              totalPrice: price * qty,
              addedBy: 'cashier-1',
              createdAt: DateTime.now(),
            ));
          }

          final payload = {
            'order': orderModel.toJson(),
            'details': details.map((d) => d.toJson()).toList(),
            if (member != null) 'member': member,
          };

          final localDb = ref.read(localDbServiceProvider);
          final syncService = ref.read(syncServiceProvider);

          await localDb.saveOrderLocally(orderId, payload);
          await syncService.syncNow();
          await ref.read(tablesProvider.notifier).deactivateTable(table.id);
        },
      ),
    );
  }

  String _fmtDuration(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()} đ';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500)),
        ]),
      );
}

class _ProductLineItem extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final VoidCallback onRemove;
  const _ProductLineItem(
      {required this.name,
      required this.qty,
      required this.price,
      required this.onRemove});

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()} đ';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('$qty',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(name, style: AppTextStyles.bodySmall)),
            Text(_fmtCurrency(price * qty),
                style: AppTextStyles.labelLarge),
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
}

class _PayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PayButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      );
}

class _NoActiveTablePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_bar_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Chưa có bàn nào đang hoạt động',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text('Vào tab Bàn để bật bàn trước.',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
}
