import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'tables_provider.dart';
import '../billing/invoice_dialog.dart';
import '../../core/providers/providers.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  Timer? _ticker;
  String _filterStatus = 'all';
  final _filters = [
    ('all', 'Tất cả'),
    ('idle', 'Trống'),
    ('active', 'Đang chơi'),
    ('booked', 'Đặt trước'),
    ('maintenance', 'Bảo trì'),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(tablesProvider);
    final filteredTables = _filterStatus == 'all'
        ? tablesState.tables
        : tablesState.tables
            .where((t) => t.status == _filterStatus)
            .toList();

    final activeCnt =
        tablesState.tables.where((t) => t.status == 'active').length;
    final idleCnt =
        tablesState.tables.where((t) => t.status == 'idle').length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sơ đồ bàn', style: AppTextStyles.headlineLarge),
                  Text(
                    '$activeCnt đang chơi · $idleCnt trống',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              // Simulator Toggle
              Row(
                children: [
                  Icon(Icons.memory_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Giả lập IoT', style: AppTextStyles.labelMedium),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: tablesState.useSimulator,
                    onChanged: (v) =>
                        ref.read(tablesProvider.notifier).toggleSimulator(v),
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── FILTER CHIPS ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final (status, label) = f;
                final count = status == 'all'
                    ? tablesState.tables.length
                    : tablesState.tables
                        .where((t) => t.status == status)
                        .length;
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: FilterChip(
                      label: Text('$label ($count)'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _filterStatus = status),
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── TABLE GRID ────────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              itemCount: filteredTables.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final table = filteredTables[index];
                return _TableCard(
                  table: table,
                  isSelected: table.id == tablesState.selectedTableId,
                  playDuration: tablesState.playDuration(table.id),
                  playCost: tablesState.playCost(table.id),
                  onSelect: () =>
                      ref.read(tablesProvider.notifier).selectTable(table.id),
                  onTogglePower: () => _handleTogglePower(table),
                  onMaintenance: () => ref
                      .read(tablesProvider.notifier)
                      .setTableMaintenance(
                          table.id, table.status != 'maintenance'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTogglePower(TableModel table) async {
    final notifier = ref.read(tablesProvider.notifier);
    final tablesState = ref.read(tablesProvider);

    if (table.status == 'idle') {
      final ok = await notifier.activateTable(table.id);
      if (!ok && mounted) {
        final forceActivate = await showDialog<bool>(
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
              'Không thể kết nối đến Relay IoT cho bàn này.\n'
              'Bạn có muốn bật bàn thủ công (không sử dụng IoT rơ-le) để tiếp tục tính giờ không?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Bật thủ công'),
              ),
            ],
          ),
        );

        if (forceActivate == true && mounted) {
          final forceOk = await notifier.activateTable(table.id, ignoreIotError: true);
          if (forceOk && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Đã bật bàn thủ công thành công.'),
              backgroundColor: AppColors.success,
            ));
          }
        }
      }
    } else if (table.status == 'active') {
      // Show invoice dialog before deactivating
      final startTime = tablesState.tableStartTimes[table.id] ?? DateTime.now();
      final endTime = DateTime.now();
      final products = tablesState.tableOrders[table.id] ?? [];
      final rate = tablesState.hourlyRates[table.tableTypeId.toString()] ?? 80000.0;
      final playMinutes = endTime.difference(startTime).inMinutes + 1;
      final playAmount = (playMinutes / 60.0) * rate;
      double productTotal = 0;
      for (final p in products) {
        productTotal +=
            (p['price'] as double) * (p['qty'] as int);
      }

      final member = tablesState.tableMembers[table.id];
      final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
      final manualDiscountPercent = tablesState.tableDiscounts[table.id] ?? 0.0;
      final discountPercent = (memberDiscountPercent + manualDiscountPercent).clamp(0.0, 100.0);
      
      final discountAmount = (playAmount + productTotal) * (discountPercent / 100.0);
      final netTotal = (playAmount + productTotal) - discountAmount;

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => InvoiceDialog(
          tableName: table.tableName,
          startTime: startTime,
          endTime: endTime,
          playMinutes: playMinutes,
          playAmount: playAmount,
          hourlyRate: rate,
          products: products,
          totalAmount: playAmount + productTotal,
          discountPercent: discountPercent,
          discountAmount: discountAmount,
          netTotal: netTotal,
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
              totalPlayTimeAmount: playAmount,
              totalProductAmount: productTotal,
              discountAmount: discountAmount,
              taxAmount: 0.0,
              totalAmount: netTotal,
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
            await notifier.deactivateTable(table.id);
          },
        ),
      );
    }
  }
}

// ─── Table Card Widget ────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final TableModel table;
  final bool isSelected;
  final Duration playDuration;
  final double playCost;
  final VoidCallback onSelect;
  final VoidCallback onTogglePower;
  final VoidCallback onMaintenance;

  const _TableCard({
    required this.table,
    required this.isSelected,
    required this.playDuration,
    required this.playCost,
    required this.onSelect,
    required this.onTogglePower,
    required this.onMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = table.status == 'active';
    final isMaintenance = table.status == 'maintenance';
    final isBooked = table.status == 'booked';

    Color cardColor;
    Color borderColor;
    Color statusDotColor;

    if (isActive) {
      cardColor = AppColors.tableActive;
      borderColor = AppColors.tableActiveAccent;
      statusDotColor = AppColors.success;
    } else if (isMaintenance) {
      cardColor = AppColors.tableMaintenance;
      borderColor = AppColors.tableMaintenanceAccent;
      statusDotColor = AppColors.error;
    } else if (isBooked) {
      cardColor = AppColors.tableBooked;
      borderColor = AppColors.tableBookedAccent;
      statusDotColor = AppColors.warning;
    } else {
      cardColor = Colors.white;
      borderColor = AppColors.border;
      statusDotColor = AppColors.textMuted;
    }

    final durationStr =
        '${playDuration.inHours.toString().padLeft(2, '0')}:'
        '${(playDuration.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(playDuration.inSeconds % 60).toString().padLeft(2, '0')}';

    final costStr = _formatCurrency(playCost);
    final typeLabel = _tableTypeLabel(table.tableTypeId);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      table.tableName,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status dot
                  _PulsingDot(color: statusDotColor, isActive: isActive),
                ],
              ),
              const SizedBox(height: 4),
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(typeLabel,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary)),
              ),
              const Spacer(),
              // ── Active info ──
              if (isActive) ...[
                Text('Thời gian', style: AppTextStyles.labelSmall),
                Text(durationStr,
                    style: AppTextStyles.mono
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tạm tính', style: AppTextStyles.labelSmall),
                Text(costStr, style: AppTextStyles.currencySmall),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMaintenance
                        ? AppColors.errorLight
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(table.status),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isMaintenance
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // ── Action button ──
              if (!isMaintenance)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTogglePower,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.error
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Tắt bàn' : 'Bật bàn',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _tableTypeLabel(int typeId) {
    return switch (typeId) {
      1 => 'Pool (Bàn lỗ)',
      2 => 'Carom (Băng)',
      3 => 'Snooker',
      _ => 'Bàn Bida',
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'idle' => '● Trống',
      'active' => '● Đang chơi',
      'booked' => '● Đặt trước',
      'maintenance' => '● Bảo trì',
      _ => status,
    };
  }

  String _formatCurrency(double amount) {
    final s = amount.toStringAsFixed(0);
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

// ─── Pulsing Status Dot ───────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool isActive;
  const _PulsingDot({required this.color, required this.isActive});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: widget.color),
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5 * _anim.value),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }
}
