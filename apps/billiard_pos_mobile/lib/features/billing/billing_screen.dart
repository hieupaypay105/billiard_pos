import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core_shared/core_shared.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/providers.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/string_utils.dart';
import '../auth/auth_provider.dart';
import '../tables/shift_provider.dart';
import '../tables/tables_provider.dart';

// Import dialogs/panels from billing directory
import 'add_product_panel.dart';
import 'discount_panel.dart';
import 'member_lookup.dart';
import 'invoice_dialog.dart';
import 'table_merge_dialog.dart';
import 'invoice_print_preview_dialog.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final String tableId;
  const BillingScreen({super.key, required this.tableId});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  Timer? _ticker;
  String? _selectedUnpaidInvoiceId;

  @override
  void initState() {
    super.initState();
    // Ticker to refresh active table's playing duration every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

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

  String _fmtDuration(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _extractApiError(Object e) {
    final raw = e.toString();
    final match = RegExp(r'^Exception:\s*(.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  // --- Start Table Activation Flow ---
  Future<void> _handleStartTable(TableModel table) async {
    final notifier = ref.read(tablesProvider.notifier);
    final currentShiftId = ref.read(currentShiftIdProvider) ?? 'shift-default';

    final confirmActivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bật bàn chơi'),
        content: Text('Bạn có chắc chắn muốn mở bàn "${table.tableName}" ngay bây giờ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bật bàn'),
          ),
        ],
      ),
    );

    if (confirmActivate != true || !mounted) return;

    final ok = await notifier.activateTable(table.id, shiftId: currentShiftId);
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
              child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
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
        final forceOk = await notifier.activateTable(table.id, ignoreIotError: true, shiftId: currentShiftId);
        if (forceOk && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã bật bàn thủ công thành công.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  // --- Deactivate Active Table Flow ---
  Future<void> _handleDeactivateTable(TableModel table) async {
    final notifier = ref.read(tablesProvider.notifier);
    final forceDeactivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tắt bàn chơi'),
        content: Text('Bạn có chắc chắn muốn tắt bàn ${table.tableName} và chuyển hóa đơn sang danh sách chờ thanh toán không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận tắt bàn'),
          ),
        ],
      ),
    );

    if (forceDeactivate == true && mounted) {
      final ok = await notifier.deactivateTableAndFreezeInvoice(table.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã tắt bàn thành công. Hóa đơn đã được đưa vào danh sách chờ thanh toán.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // --- Checkout Flow for Active Tables ---
  Future<void> _handleCheckoutTap(
    BuildContext context,
    TableModel table,
    String initialStatus,
    double playAmount,
    double productTotal,
    double discountPlayPercent,
    double discountServicePercent,
    double discountBillPercent,
    double discountAmount,
    double netTotal,
    DateTime startTime,
    List<Map<String, dynamic>> products,
    double rate,
    Map<String, dynamic>? member,
  ) async {
    final tablesState = ref.read(tablesProvider);
    final initialNote = tablesState.tableNotes[table.id];
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id ?? 'system';
    final currentShiftId = ref.read(currentShiftIdProvider) ?? 'shift-default';
    final localDb = ref.read(localDbServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    final tablesNotifier = ref.read(tablesProvider.notifier);

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Bàn chơi chưa tắt'),
        content: Text('Bàn "${table.tableName}" đang hoạt động. Bạn có chắc chắn muốn tắt bàn trước khi thanh toán không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('bypass'),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('deactivate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tắt bàn'),
          ),
        ],
      ),
    );

    if (action == 'deactivate') {
      final endTime = DateTime.now();
      final baseMinutes = endTime.difference(startTime).inMinutes + 1;
      final billedMinutes = ((baseMinutes + 4) ~/ 5) * 5;
      final playMinutes = billedMinutes + (tablesState.tableExtraPlayMinutes[table.id] ?? 0);
      final calcPlayAmount = (billedMinutes / 60.0) * rate + (tablesState.tableExtraPlayAmounts[table.id] ?? 0.0);
      
      final invProductTotal = products.fold(0.0,
          (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

      final invMemberDiscountPercent = member != null ? (double.tryParse(member['discount']?.toString() ?? '') ?? 0.0) : 0.0;
      final invPlayPercent = tablesState.tablePlayDiscounts[table.id] ?? 0.0;
      final invServicePercent = tablesState.tableServiceDiscounts[table.id] ?? 0.0;
      final invBillPercent = tablesState.tableBillDiscounts[table.id] ?? 0.0;
      
      final invPlayDiscountAmount = calcPlayAmount * (invPlayPercent / 100.0);
      final invServiceDiscountAmount = invProductTotal * (invServicePercent / 100.0);
      final invBillDiscountPercentTotal = (invBillPercent + invMemberDiscountPercent).clamp(0.0, 100.0);
      final invBillDiscountAmount = (calcPlayAmount + invProductTotal - invPlayDiscountAmount - invServiceDiscountAmount) * (invBillDiscountPercentTotal / 100.0);
      final invDiscountAmount = invPlayDiscountAmount + invServiceDiscountAmount + invBillDiscountAmount;
      final invNetTotal = (calcPlayAmount + invProductTotal) - invDiscountAmount;
      final orderId = table.currentOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';

      final ok = await tablesNotifier.deactivateTableAndFreezeInvoice(table.id);
      if (ok) {
        final newInvoice = UnpaidInvoice(
          id: orderId,
          tableId: table.id,
          tableName: table.tableName,
          startTime: startTime,
          endTime: endTime,
          playMinutes: playMinutes,
          playAmount: calcPlayAmount,
          hourlyRate: rate,
          products: List<Map<String, dynamic>>.from(products),
          discountPlayPercent: invPlayPercent,
          discountServicePercent: invServicePercent,
          discountBillPercent: invBillPercent,
          manualDiscountPercent: invBillPercent,
          member: member,
          note: initialNote,
        );

        tablesNotifier.selectUnpaidInvoice(newInvoice.id);

        if (context.mounted) {
          await _checkoutUnpaidInvoice(
            context: context,
            currentUserId: currentUserId,
            currentShiftId: currentShiftId,
            localDb: localDb,
            syncService: syncService,
            tablesNotifier: tablesNotifier,
            invoice: newInvoice,
            initialStatus: initialStatus,
            playAmount: calcPlayAmount,
            productTotal: invProductTotal,
            discountPlayPercent: invPlayPercent,
            discountServicePercent: invServicePercent,
            discountBillPercent: invBillPercent,
            discountAmount: invDiscountAmount,
            netTotal: invNetTotal,
            startTime: newInvoice.startTime,
            endTime: newInvoice.endTime,
            products: products,
            rate: newInvoice.hourlyRate,
            member: member,
          );
        }
      }
    } else if (action == 'bypass') {
      if (context.mounted) {
        await _checkout(
          context,
          table,
          initialStatus,
          playAmount,
          productTotal,
          discountPlayPercent,
          discountServicePercent,
          discountBillPercent,
          discountAmount,
          netTotal,
          startTime,
          products,
          rate,
          member,
        );
      }
    }
  }

  Future<void> _checkout(
    BuildContext context,
    TableModel table,
    String initialStatus,
    double playAmount,
    double productTotal,
    double discountPlayPercent,
    double discountServicePercent,
    double discountBillPercent,
    double discountAmount,
    double netTotal,
    DateTime startTime,
    List<Map<String, dynamic>> products,
    double rate,
    Map<String, dynamic>? member,
  ) async {
    final endTime = DateTime.now();
    final baseMinutes = endTime.difference(startTime).inMinutes + 1;
    final billedMinutes = ((baseMinutes + 4) ~/ 5) * 5;
    final playMinutes = billedMinutes + (ref.read(tablesProvider).tableExtraPlayMinutes[table.id] ?? 0);
    final finalPlayAmount = (billedMinutes / 60.0) * rate;
    final finalProductTotal =
        products.fold(0.0, (s, p) => s + (p['price'] as double) * (p['qty'] as int));
    
    final memberDiscountPercent = member != null ? (double.tryParse(member['discount']?.toString() ?? '') ?? 0.0) : 0.0;
    final playDiscountAmount = finalPlayAmount * (discountPlayPercent / 100.0);
    final serviceDiscountAmount = finalProductTotal * (discountServicePercent / 100.0);
    final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
    final billDiscountAmount = (finalPlayAmount + finalProductTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
    final finalDiscountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
    final finalNetTotal = (finalPlayAmount + finalProductTotal) - finalDiscountAmount;

    final initialNote = ref.read(tablesProvider).tableNotes[table.id];
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id ?? 'system';
    final currentShiftId = ref.read(currentShiftIdProvider) ?? 'shift-default';
    final localDb = ref.read(localDbServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    final tablesNotifier = ref.read(tablesProvider.notifier);

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
        discountPlayPercent: discountPlayPercent,
        discountServicePercent: discountServicePercent,
        discountBillPercent: discountBillPercent,
        discountAmount: finalDiscountAmount,
        netTotal: finalNetTotal,
        totalAmount: finalPlayAmount + finalProductTotal,
        initialStatus: initialStatus,
        member: member,
        note: initialNote,
        onConfirm: ({
          required status,
          required paymentMethod,
          required discountAmount,
          required netTotal,
          required note,
        }) async {
          final orderId = table.currentOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';

          final orderModel = OrderModel(
            id: orderId,
            tableId: table.id,
            memberId: member?['id']?.toString(),
            shiftId: currentShiftId,
            status: status,
            startTime: startTime,
            endTime: endTime,
            totalPlayTimeMinutes: playMinutes,
            totalPlayTimeAmount: finalPlayAmount,
            totalProductAmount: finalProductTotal,
            discountAmount: discountAmount,
            taxAmount: 0.0,
            totalAmount: netTotal,
            paymentMethod: paymentMethod,
            createdBy: currentUserId,
            closedBy: currentUserId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            note: note,
          );

          final details = <OrderDetailModel>[];
          for (int i = 0; i < products.length; i++) {
            final p = products[i];
            final pid = p['product_id']?.toString() ?? '';
            final qty = int.tryParse(p['qty']?.toString() ?? '') ?? 1;
            final price = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
            details.add(OrderDetailModel(
              id: const Uuid().v4(),
              orderId: orderId,
              productId: pid,
              quantity: qty,
              unitPrice: price,
              totalPrice: price * qty,
              addedBy: currentUserId,
              createdAt: DateTime.now(),
            ));
          }

          final payload = {
            'order': orderModel.toJson(),
            'details': details.map((d) => d.toJson()).toList(),
            if (member != null) 'member': member,
          };

          try {
            await localDb.saveOrderLocally(orderId, payload);
            final syncResult = await syncService.syncNow();
            if (!syncResult.success && syncResult.message.isNotEmpty && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(syncResult.message),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_extractApiError(e)),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ));
            }
            rethrow;
          }

          await tablesNotifier.deactivateTable(table.id);
          if (context.mounted) {
            context.pop(); // Return to main tables list
          }
        },
      ),
    );
  }

  // --- Checkout Flow for Unpaid Invoices ---
  Future<void> _handleCheckoutUnpaid(
    BuildContext context,
    UnpaidInvoice invoice,
    String initialStatus,
    double playAmount,
    double productTotal,
    double discountPlayPercent,
    double discountServicePercent,
    double discountBillPercent,
    double discountAmount,
    double netTotal,
    DateTime startTime,
    DateTime endTime,
    List<Map<String, dynamic>> products,
    double rate,
    Map<String, dynamic>? member,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id ?? 'system';
    final currentShiftId = ref.read(currentShiftIdProvider) ?? 'shift-default';
    final localDb = ref.read(localDbServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    final tablesNotifier = ref.read(tablesProvider.notifier);

    await _checkoutUnpaidInvoice(
      context: context,
      currentUserId: currentUserId,
      currentShiftId: currentShiftId,
      localDb: localDb,
      syncService: syncService,
      tablesNotifier: tablesNotifier,
      invoice: invoice,
      initialStatus: initialStatus,
      playAmount: playAmount,
      productTotal: productTotal,
      discountPlayPercent: discountPlayPercent,
      discountServicePercent: discountServicePercent,
      discountBillPercent: discountBillPercent,
      discountAmount: discountAmount,
      netTotal: netTotal,
      startTime: startTime,
      endTime: endTime,
      products: products,
      rate: rate,
      member: member,
    );
  }

  Future<void> _checkoutUnpaidInvoice({
    required BuildContext context,
    required String currentUserId,
    required String currentShiftId,
    required LocalDbService localDb,
    required SyncService syncService,
    required TablesNotifier tablesNotifier,
    required UnpaidInvoice invoice,
    required String initialStatus,
    required double playAmount,
    required double productTotal,
    required double discountPlayPercent,
    required double discountServicePercent,
    required double discountBillPercent,
    required double discountAmount,
    required double netTotal,
    required DateTime startTime,
    required DateTime endTime,
    required List<Map<String, dynamic>> products,
    required double rate,
    required Map<String, dynamic>? member,
  }) async {
    final playMinutes = invoice.playMinutes;
    final finalPlayAmount = playAmount;
    final finalProductTotal = productTotal;
    final finalDiscountAmount = discountAmount;
    final finalNetTotal = netTotal;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => InvoiceDialog(
        tableName: invoice.tableName,
        startTime: startTime,
        endTime: endTime,
        playMinutes: playMinutes,
        playAmount: finalPlayAmount,
        hourlyRate: rate,
        products: products,
        discountPlayPercent: discountPlayPercent,
        discountServicePercent: discountServicePercent,
        discountBillPercent: discountBillPercent,
        discountAmount: finalDiscountAmount,
        netTotal: finalNetTotal,
        totalAmount: finalPlayAmount + finalProductTotal,
        initialStatus: initialStatus,
        member: member,
        note: invoice.note,
        onConfirm: ({
          required status,
          required paymentMethod,
          required discountAmount,
          required netTotal,
          required note,
        }) async {
          final orderId = invoice.id;

          final orderModel = OrderModel(
            id: orderId,
            tableId: invoice.tableId,
            memberId: member?['id']?.toString(),
            shiftId: currentShiftId,
            status: status,
            startTime: startTime,
            endTime: endTime,
            totalPlayTimeMinutes: playMinutes,
            totalPlayTimeAmount: finalPlayAmount,
            totalProductAmount: finalProductTotal,
            discountAmount: discountAmount,
            taxAmount: 0.0,
            totalAmount: netTotal,
            paymentMethod: paymentMethod,
            createdBy: currentUserId,
            closedBy: currentUserId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            note: note,
          );

          final details = <OrderDetailModel>[];
          for (int i = 0; i < products.length; i++) {
            final p = products[i];
            final pid = p['product_id']?.toString() ?? '';
            final qty = int.tryParse(p['qty']?.toString() ?? '') ?? 1;
            final price = double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
            details.add(OrderDetailModel(
              id: const Uuid().v4(),
              orderId: orderId,
              productId: pid,
              quantity: qty,
              unitPrice: price,
              totalPrice: price * qty,
              addedBy: currentUserId,
              createdAt: DateTime.now(),
            ));
          }

          final payload = {
            'order': orderModel.toJson(),
            'details': details.map((d) => d.toJson()).toList(),
            if (member != null) 'member': member,
          };

          try {
            await localDb.saveOrderLocally(orderId, payload);
            final syncResult = await syncService.syncNow();
            if (!syncResult.success && syncResult.message.isNotEmpty && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(syncResult.message),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_extractApiError(e)),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ));
            }
            rethrow;
          }

          tablesNotifier.completeUnpaidInvoicePayment(invoice.id);
          setState(() {
            _selectedUnpaidInvoiceId = null;
          });
          if (context.mounted) {
            context.pop(); // Return to main tables list
          }
        },
      ),
    );
  }

  // --- Add Product Sheet Flow ---
  void _openAddProductPanel(BuildContext context, String targetId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // Modal Drag Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('Thêm dịch vụ', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: AddProductPanel(tableId: targetId),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tablesProvider);
    
    // Find matching table
    final tableIndex = state.tables.indexWhere((t) => t.id == widget.tableId);
    if (tableIndex < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy thông tin bàn chơi.')),
      );
    }
    final table = state.tables[tableIndex];
    final isTableActive = table.status == 'active';

    // Check if we are viewing a specific unpaid invoice
    UnpaidInvoice? selectedInvoice;
    if (_selectedUnpaidInvoiceId != null) {
      final idx = state.unpaidInvoices.indexWhere((inv) => inv.id == _selectedUnpaidInvoiceId);
      if (idx >= 0) {
        selectedInvoice = state.unpaidInvoices[idx];
      }
    }

    if (selectedInvoice != null) {
      return _buildUnpaidInvoiceDetailScreen(context, selectedInvoice, state);
    }

    if (!isTableActive) {
      return _buildIdleTableScreen(context, table, state);
    }

    return _buildActiveTableScreen(context, table, state);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Builder: Active Table Detail
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActiveTableScreen(BuildContext context, TableModel table, TablesState state) {
    final products = state.tableOrders[table.id] ?? [];
    final pendingProducts = state.tablePendingOrders[table.id] ?? [];
    final startTime = state.tableStartTimes[table.id] ?? DateTime.now();
    final endTime = DateTime.now();
    final rate = state.getTableHourlyRate(table, startTime);

    final baseMinutes = endTime.difference(startTime).inMinutes + 1;
    final billedMinutes = ((baseMinutes + 4) ~/ 5) * 5;
    final playMinutes = billedMinutes + (state.tableExtraPlayMinutes[table.id] ?? 0);
    final playAmount = (billedMinutes / 60.0) * rate + (state.tableExtraPlayAmounts[table.id] ?? 0.0);
    final productTotal = products.fold(0.0,
        (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

    final member = state.tableMembers[table.id];
    final memberDiscountPercent = member != null ? (double.tryParse(member['discount']?.toString() ?? '') ?? 0.0) : 0.0;
    
    final discountPlayPercent = state.tablePlayDiscounts[table.id] ?? 0.0;
    final discountServicePercent = state.tableServiceDiscounts[table.id] ?? 0.0;
    final discountBillPercent = state.tableBillDiscounts[table.id] ?? 0.0;
    
    final playDiscountAmount = playAmount * (discountPlayPercent / 100.0);
    final serviceDiscountAmount = productTotal * (discountServicePercent / 100.0);
    final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
    final billDiscountAmount = (playAmount + productTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
    final discountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
    final netTotal = (playAmount + productTotal) - discountAmount;

    final elapsed = endTime.difference(startTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(table.tableName),
        actions: [
          if (state.connectedIp == null)
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.red),
              tooltip: 'Tắt bàn',
              onPressed: () => _handleDeactivateTable(table),
            )
        ],
      ),
      body: Column(
        children: [
          if (state.connectedIp != null)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.sync, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đang đồng bộ với máy thu ngân. Thao tác thanh toán được thực hiện tại quầy.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ── Timer Ticking Section (Compact Layout) ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.play_circle_fill, color: AppColors.success, size: 14),
                        const SizedBox(width: 4),
                        Text('Đang chơi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success, fontFamily: 'Inter')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Giờ vào: ${_fmtTime(startTime)} · ${_fmtCurrency(rate)}/h', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtDuration(elapsed),
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text('$playMinutes phút', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontFamily: 'Inter')),
                  ],
                ),
              ],
            ),
          ),

          // Member & Discounts Badges
          _buildAppliedMemberAndDiscounts(
            context: context,
            targetId: table.id,
            member: member,
            discountPlayPercent: discountPlayPercent,
            discountServicePercent: discountServicePercent,
            discountBillPercent: discountBillPercent,
          ),

          // ── Segment Section: Service list ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DỊCH VỤ ĐÃ GỌI', style: AppTextStyles.titleSmall),
                TextButton.icon(
                  onPressed: () => _openAddProductPanel(context, table.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm'),
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, foregroundColor: AppColors.primary),
                )
              ],
            ),
          ),

          final buildProductRow = (BuildContext context, Map<String, dynamic> p, {required bool isLocked}) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(_fmtCurrency(p['price'] as double), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.remove_circle_outline, color: isLocked ? AppColors.textMuted : AppColors.textSecondary),
                        onPressed: isLocked ? null : () => ref.read(tablesProvider.notifier).updateProductQty(table.id, p['product_id'] as String, -1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('${p['qty']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLocked ? AppColors.textMuted : AppColors.textPrimary)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.add_circle_outline, color: isLocked ? AppColors.textMuted : AppColors.primary),
                        onPressed: isLocked ? null : () => ref.read(tablesProvider.notifier).updateProductQty(table.id, p['product_id'] as String, 1),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: isLocked ? null : () => ref.read(tablesProvider.notifier).removeProductFromTable(table.id, p['product_id'] as String),
                        child: Icon(Icons.delete_outline, color: isLocked ? AppColors.textMuted : Colors.redAccent, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            );
          };

          Expanded(
            child: (products.isEmpty && pendingProducts.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text('Bàn chưa gọi dịch vụ nào', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      if (products.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Đã duyệt (${products.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Inter')),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final p = products[idx];
                              final isLocked = state.connectedIp != null;
                              return buildProductRow(context, p, isLocked: isLocked);
                            },
                            childCount: products.length,
                          ),
                        ),
                      ],
                      if (pendingProducts.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Chờ duyệt (${pendingProducts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange, fontFamily: 'Inter')),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final p = pendingProducts[idx];
                              return buildProductRow(context, p, isLocked: false);
                            },
                            childCount: pendingProducts.length,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          if (state.connectedIp == null)
            // ── Quick Operations Grid ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.2,
                children: [
                  _buildQuickActionBtn(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Chọn TV',
                    color: AppColors.primary,
                    onTap: () => showDialog(context: context, builder: (_) => MemberLookupDialog(tableId: table.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.local_offer_outlined,
                    label: 'Khuyến mãi',
                    color: AppColors.accent,
                    onTap: () => showDialog(context: context, builder: (_) => DiscountPanel(tableId: table.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.merge_type,
                    label: 'Gộp bàn',
                    color: AppColors.info,
                    onTap: () => showDialog(context: context, builder: (_) => TableMergeDialog(sourceTableId: table.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.swap_horiz,
                    label: 'Chuyển bàn',
                    color: AppColors.transfer,
                    onTap: () => showDialog(context: context, builder: (_) => TableTransferDialog(sourceTableId: table.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.print_outlined,
                    label: 'In hóa đơn',
                    color: Colors.blueGrey,
                    onTap: () {
                      final currentUser = ref.read(currentUserProvider);
                      final cashierName = currentUser?.displayName ?? currentUser?.username ?? 'Hệ thống';
                      final activeShift = ref.read(shiftProvider).activeShift;

                      showDialog(
                        context: context,
                        builder: (_) => InvoicePrintPreviewDialog(
                          tableName: table.tableName,
                          startTime: startTime,
                          endTime: endTime,
                          playMinutes: playMinutes,
                          playAmount: playAmount,
                          hourlyRate: rate,
                          products: products,
                          totalAmount: playAmount + productTotal,
                          discountPlayPercent: discountPlayPercent,
                          discountServicePercent: discountServicePercent,
                          discountBillPercent: discountBillPercent,
                          discountPercent: discountBillPercent,
                          discountAmount: discountAmount,
                          netTotal: netTotal,
                          member: member,
                          cashierName: cashierName,
                          shiftLabel: activeShift != null ? 'Ca ${activeShift.id.replaceAll('shift-', '')}' : null,
                          status: 'paid',
                        ),
                      );
                    },
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.notes_outlined,
                    label: 'Ghi chú',
                    color: Colors.brown,
                    onTap: () async {
                      final notifier = ref.read(tablesProvider.notifier);
                      final ctrl = TextEditingController(text: state.tableNotes[table.id] ?? '');
                      final note = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Ghi chú bàn'),
                          content: TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(hintText: 'Nhập ghi chú...'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Lưu')),
                          ],
                        ),
                      );
                      if (note != null) {
                        notifier.state = notifier.state.copyWith(
                          tableNotes: {...notifier.state.tableNotes, table.id: note},
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

          // ── Summary & Payment Buttons (Sticky Bottom) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rate > 0)
                    _buildSummaryRow('Tiền giờ chơi', _fmtCurrency(playAmount)),
                  _buildSummaryRow('Dịch vụ', _fmtCurrency(productTotal)),
                  if (discountPlayPercent > 0)
                    _buildSummaryRow(
                      'Chiết khấu giờ chơi (${discountPlayPercent.toInt()}%)',
                      '-${_fmtCurrency(playDiscountAmount)}',
                      isDiscount: true,
                    ),
                  if (discountServicePercent > 0)
                    _buildSummaryRow(
                      'Chiết khấu dịch vụ (${discountServicePercent.toInt()}%)',
                      '-${_fmtCurrency(serviceDiscountAmount)}',
                      isDiscount: true,
                    ),
                  if (discountBillPercent > 0 || memberDiscountPercent > 0)
                    _buildSummaryRow(
                      memberDiscountPercent > 0
                          ? 'Chiết khấu HĐ & TV (${(discountBillPercent + memberDiscountPercent).toInt()}%)'
                          : 'Chiết khấu hóa đơn (${discountBillPercent.toInt()}%)',
                      '-${_fmtCurrency(billDiscountAmount)}',
                      isDiscount: true,
                    ),
                  const Divider(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TỔNG CỘNG:', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      Text(_fmtCurrency(netTotal), style: AppTextStyles.currency.copyWith(fontSize: 22)),
                    ],
                  ),
                  if (state.connectedIp == null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleCheckoutTap(
                              context,
                              table,
                              'unpaid',
                              playAmount,
                              productTotal,
                              discountPlayPercent,
                              discountServicePercent,
                              discountBillPercent,
                              discountAmount,
                              netTotal,
                              startTime,
                              products,
                              rate,
                              member,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error, width: 1.5),
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Không thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleCheckoutTap(
                              context,
                              table,
                              'paid',
                              playAmount,
                              productTotal,
                              discountPlayPercent,
                              discountServicePercent,
                              discountBillPercent,
                              discountAmount,
                              netTotal,
                              startTime,
                              products,
                              rate,
                              member,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Builder: Idle Table Detail (Choose activation, or list pending invoices)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildIdleTableScreen(BuildContext context, TableModel table, TablesState state) {
    // Filter unpaid invoices that belong to this table
    final pendingInvoices = state.unpaidInvoices.where((inv) => inv.tableId == table.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${table.tableName} (Trống)')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Icon(Icons.table_bar_outlined, size: 72, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            Text(table.tableName, style: AppTextStyles.displayMedium),
            const SizedBox(height: 4),
            Text('Bàn đang trống', style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () => _handleStartTable(table),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Bật bàn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            if (pendingInvoices.isNotEmpty) ...[
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('HÓA ĐƠN CHỜ THANH TOÁN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: pendingInvoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final inv = pendingInvoices[idx];
                  final netTotal = inv.playAmount +
                      inv.products.fold(0.0, (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedUnpaidInvoiceId = inv.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_off_outlined, color: AppColors.accent, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${inv.playMinutes} phút', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dừng lúc: ${_fmtTime(inv.endTime)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_fmtCurrency(netTotal), style: AppTextStyles.currencySmall),
                              const SizedBox(height: 4),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Builder: Unpaid/Suspended Invoice Details Screen
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildUnpaidInvoiceDetailScreen(BuildContext context, UnpaidInvoice invoice, TablesState state) {
    final products = invoice.products;
    final pendingProducts = state.tablePendingOrders[invoice.id] ?? [];
    final startTime = invoice.startTime;
    final endTime = invoice.endTime;
    final rate = invoice.hourlyRate;
    final playAmount = invoice.playAmount;
    final productTotal = products.fold(0.0,
        (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

    final member = invoice.member;
    final memberDiscountPercent = member != null ? (double.tryParse(member['discount']?.toString() ?? '') ?? 0.0) : 0.0;
    
    final discountPlayPercent = invoice.discountPlayPercent;
    final discountServicePercent = invoice.discountServicePercent;
    final discountBillPercent = invoice.discountBillPercent;
    
    final playDiscountAmount = playAmount * (discountPlayPercent / 100.0);
    final serviceDiscountAmount = productTotal * (discountServicePercent / 100.0);
    final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
    final billDiscountAmount = (playAmount + productTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
    final discountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
    final netTotal = (playAmount + productTotal) - discountAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${invoice.tableName} (HĐ Chờ)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedUnpaidInvoiceId = null;
            });
          },
        ),
      ),
      body: Column(
        children: [
          if (state.connectedIp != null)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.sync, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đang đồng bộ với máy thu ngân. Thao tác thanh toán được thực hiện tại quầy.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Header Summary Card (Compact Layout)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pause_circle_filled, color: AppColors.accent, size: 14),
                        const SizedBox(width: 4),
                        Text('Tạm dừng / Đang chờ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent, fontFamily: 'Inter')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${_fmtTime(startTime)} - ${_fmtTime(endTime)} · ${_fmtCurrency(rate)}/h', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${invoice.playMinutes} phút',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Text('Giờ: ${_fmtCurrency(playAmount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontFamily: 'Inter')),
                  ],
                ),
              ],
            ),
          ),

          // Member & Discounts Badges
          _buildAppliedMemberAndDiscounts(
            context: context,
            targetId: invoice.id,
            member: member,
            discountPlayPercent: discountPlayPercent,
            discountServicePercent: discountServicePercent,
            discountBillPercent: discountBillPercent,
          ),

          // Product List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DỊCH VỤ ĐÃ GỌI', style: AppTextStyles.titleSmall),
                TextButton.icon(
                  onPressed: () => _openAddProductPanel(context, invoice.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm'),
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, foregroundColor: AppColors.primary),
                )
              ],
            ),
          ),

          final buildProductRow = (BuildContext context, Map<String, dynamic> p, {required bool isLocked}) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] as String, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(_fmtCurrency(p['price'] as double), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.remove_circle_outline, color: isLocked ? AppColors.textMuted : AppColors.textSecondary),
                        onPressed: isLocked ? null : () => ref.read(tablesProvider.notifier).updateProductQty(invoice.id, p['product_id'] as String, -1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('${p['qty']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLocked ? AppColors.textMuted : AppColors.textPrimary)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.add_circle_outline, color: isLocked ? AppColors.textMuted : AppColors.primary),
                        onPressed: isLocked ? null : () => ref.read(tablesProvider.notifier).updateProductQty(invoice.id, p['product_id'] as String, 1),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: isLocked ? null : () => ref.read(tablesProvider.notifier).removeProductFromTable(invoice.id, p['product_id'] as String),
                        child: Icon(Icons.delete_outline, color: isLocked ? AppColors.textMuted : Colors.redAccent, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            );
          };

          Expanded(
            child: (products.isEmpty && pendingProducts.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text('Chưa gọi dịch vụ nào', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      if (products.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Đã duyệt (${products.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Inter')),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final p = products[idx];
                              final isLocked = state.connectedIp != null;
                              return buildProductRow(context, p, isLocked: isLocked);
                            },
                            childCount: products.length,
                          ),
                        ),
                      ],
                      if (pendingProducts.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Chờ duyệt (${pendingProducts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange, fontFamily: 'Inter')),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final p = pendingProducts[idx];
                              return buildProductRow(context, p, isLocked: false);
                            },
                            childCount: pendingProducts.length,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // Quick Operations Grid
          if (state.connectedIp == null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.2,
                children: [
                  _buildQuickActionBtn(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Chọn TV',
                    color: AppColors.primary,
                    onTap: () => showDialog(context: context, builder: (_) => MemberLookupDialog(tableId: invoice.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.local_offer_outlined,
                    label: 'Khuyến mãi',
                    color: AppColors.accent,
                    onTap: () => showDialog(context: context, builder: (_) => DiscountPanel(tableId: invoice.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.merge_type,
                    label: 'Gộp bàn',
                    color: AppColors.info,
                    onTap: () => showDialog(context: context, builder: (_) => TableMergeDialog(sourceInvoiceId: invoice.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.swap_horiz,
                    label: 'Chuyển bàn',
                    color: AppColors.transfer,
                    onTap: () => showDialog(context: context, builder: (_) => TableTransferDialog(sourceInvoiceId: invoice.id)),
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.print_outlined,
                    label: 'In hóa đơn',
                    color: Colors.blueGrey,
                    onTap: () {
                      final currentUser = ref.read(currentUserProvider);
                      final cashierName = currentUser?.displayName ?? currentUser?.username ?? 'Hệ thống';
                      final activeShift = ref.read(shiftProvider).activeShift;

                      showDialog(
                        context: context,
                        builder: (_) => InvoicePrintPreviewDialog(
                          tableName: invoice.tableName,
                          startTime: startTime,
                          endTime: endTime,
                          playMinutes: invoice.playMinutes,
                          playAmount: playAmount,
                          hourlyRate: rate,
                          products: products,
                          totalAmount: playAmount + productTotal,
                          discountPlayPercent: discountPlayPercent,
                          discountServicePercent: discountServicePercent,
                          discountBillPercent: discountBillPercent,
                          discountPercent: discountBillPercent,
                          discountAmount: discountAmount,
                          netTotal: netTotal,
                          member: member,
                          cashierName: cashierName,
                          shiftLabel: activeShift != null ? 'Ca ${activeShift.id.replaceAll('shift-', '')}' : null,
                          status: 'paid',
                        ),
                      );
                    },
                  ),
                  _buildQuickActionBtn(
                    icon: Icons.notes_outlined,
                    label: 'Ghi chú',
                    color: Colors.brown,
                    onTap: () async {
                      final notifier = ref.read(tablesProvider.notifier);
                      final ctrl = TextEditingController(text: invoice.note ?? '');
                      final note = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Ghi chú hóa đơn'),
                          content: TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(hintText: 'Nhập ghi chú...'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Lưu')),
                          ],
                        ),
                      );
                      if (note != null) {
                        final updated = List<UnpaidInvoice>.from(notifier.state.unpaidInvoices);
                        final index = updated.indexWhere((inv) => inv.id == invoice.id);
                        if (index >= 0) {
                          updated[index] = updated[index].copyWith(note: note);
                          notifier.state = notifier.state.copyWith(unpaidInvoices: updated);
                          notifier.selectTable(widget.tableId); // Triggers save state internally or forces rebuild
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

          // Summary and Payment
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rate > 0)
                    _buildSummaryRow('Tiền giờ chơi', _fmtCurrency(playAmount)),
                  _buildSummaryRow('Dịch vụ', _fmtCurrency(productTotal)),
                  if (discountPlayPercent > 0)
                    _buildSummaryRow(
                      'Chiết khấu giờ chơi (${discountPlayPercent.toInt()}%)',
                      '-${_fmtCurrency(playDiscountAmount)}',
                      isDiscount: true,
                    ),
                  if (discountServicePercent > 0)
                    _buildSummaryRow(
                      'Chiết khấu dịch vụ (${discountServicePercent.toInt()}%)',
                      '-${_fmtCurrency(serviceDiscountAmount)}',
                      isDiscount: true,
                    ),
                  if (discountBillPercent > 0 || memberDiscountPercent > 0)
                    _buildSummaryRow(
                      memberDiscountPercent > 0
                          ? 'Chiết khấu HĐ & TV (${(discountBillPercent + memberDiscountPercent).toInt()}%)'
                          : 'Chiết khấu hóa đơn (${discountBillPercent.toInt()}%)',
                      '-${_fmtCurrency(billDiscountAmount)}',
                      isDiscount: true,
                    ),
                  const Divider(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TỔNG CỘNG:', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      Text(_fmtCurrency(netTotal), style: AppTextStyles.currency.copyWith(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (state.connectedIp == null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleCheckoutUnpaid(
                              context,
                              invoice,
                              'unpaid',
                              playAmount,
                              productTotal,
                              discountPlayPercent,
                              discountServicePercent,
                              discountBillPercent,
                              discountAmount,
                              netTotal,
                              startTime,
                              endTime,
                              products,
                              rate,
                              member,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error, width: 1.5),
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Không thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleCheckoutUnpaid(
                              context,
                              invoice,
                              'paid',
                              playAmount,
                              productTotal,
                              discountPlayPercent,
                              discountServicePercent,
                              discountBillPercent,
                              discountAmount,
                              netTotal,
                              startTime,
                              endTime,
                              products,
                              rate,
                              member,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Quick Action Button Helper
  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build applied member and discounts badges with removal actions
  Widget _buildAppliedMemberAndDiscounts({
    required BuildContext context,
    required String targetId,
    required Map<String, dynamic>? member,
    required double discountPlayPercent,
    required double discountServicePercent,
    required double discountBillPercent,
  }) {
    if (member == null && discountPlayPercent <= 0 && discountServicePercent <= 0 && discountBillPercent <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
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
                      'Thành viên: ${member['full_name']} (${member['tier']} -${member['discount']}%)',
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
                    onTap: () {
                      ref.read(tablesProvider.notifier).removeMember(targetId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Đã bỏ thành viên'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.cancel, size: 20, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          if (discountPlayPercent > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
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
                      'KM tiền giờ: -${discountPlayPercent.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(tablesProvider.notifier).removeDiscount(targetId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Đã bỏ khuyến mãi giờ chơi'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.cancel, size: 20, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          if (discountServicePercent > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
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
                      'KM dịch vụ: -${discountServicePercent.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(tablesProvider.notifier).removeDiscount(targetId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Đã bỏ khuyến mãi dịch vụ'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.cancel, size: 20, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          if (discountBillPercent > 0)
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
                      'KM hóa đơn: -${discountBillPercent.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(tablesProvider.notifier).removeDiscount(targetId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Đã bỏ khuyến mãi hóa đơn'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(Icons.cancel, size: 20, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Summary Row Helper Widget
  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDiscount ? AppColors.accent : AppColors.textSecondary,
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDiscount ? AppColors.accent : AppColors.textPrimary,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
