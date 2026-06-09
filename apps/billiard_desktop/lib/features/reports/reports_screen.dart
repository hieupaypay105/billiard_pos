import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/providers.dart';
import '../../features/sync/sync_provider.dart';
import '../billing/invoice_print_preview_dialog.dart';
import 'report_print_preview_dialog.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class _ReportRow {
  final String date;
  final int count;
  final double play;
  final double service;
  final double total;

  const _ReportRow({
    required this.date,
    required this.count,
    required this.play,
    required this.service,
    required this.total,
  });
}

class _ReportData {
  final List<dynamic> orders;
  final bool isOffline;

  const _ReportData({this.orders = const [], this.isOffline = false});
}

// ─── Mock fallback data ──────────────────────────────────────────────────────

final _mockOrders = [
  {
    'id': 'mock-ord-1',
    'table_id': 'table-1',
    'table_name': 'Bàn 1',
    'status': 'paid',
    'start_time': '2026-06-08 10:00:00',
    'end_time': '2026-06-08 11:30:00',
    'total_play_time_minutes': 90,
    'total_play_time_amount': 90000.0,
    'total_product_amount': 45000.0,
    'discount_amount': 10000.0,
    'total_amount': 125000.0,
    'payment_method': 'cash',
    'created_by': 'admin',
    'closed_by': 'admin',
    'created_at': '2026-06-08 10:00:00',
  },
  {
    'id': 'mock-ord-2',
    'table_id': 'table-2',
    'table_name': 'Bàn 2',
    'status': 'unpaid',
    'start_time': '2026-06-08 12:00:00',
    'end_time': '2026-06-08 13:00:00',
    'total_play_time_minutes': 60,
    'total_play_time_amount': 60000.0,
    'total_product_amount': 20000.0,
    'discount_amount': 80000.0,
    'total_amount': 0.0,
    'payment_method': null,
    'created_by': 'cashier1',
    'closed_by': 'cashier1',
    'created_at': '2026-06-08 12:00:00',
    'note': 'Khách quen chiết khấu 100%',
  },
  {
    'id': 'mock-ord-3',
    'table_id': 'table-3',
    'table_name': 'Bàn 3',
    'status': 'cancelled',
    'start_time': '2026-06-08 14:00:00',
    'end_time': '2026-06-08 14:15:00',
    'total_play_time_minutes': 15,
    'total_play_time_amount': 15000.0,
    'total_product_amount': 0.0,
    'discount_amount': 0.0,
    'total_amount': 0.0,
    'payment_method': null,
    'created_by': 'admin',
    'closed_by': 'admin',
    'created_at': '2026-06-08 14:00:00',
    'note': 'Hủy do khách đổi ý',
  },
];

// ─── Providers & Helpers ───────────────────────────────────────────────────────

final _reportDataProvider = FutureProvider.family<_ReportData, DateTimeRange>((
  ref,
  range,
) async {
  final syncState = ref.watch(syncStateProvider);
  final isOnline = syncState.isOnline;

  if (isOnline) {
    try {
      final api = ref.read(apiClientProvider);
      final dateFrom = _fmtIso(range.start);
      final dateTo = _fmtIso(range.end);

      final List<dynamic> orders = await api.getAllOrders(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      return _ReportData(orders: orders, isOffline: false);
    } catch (e) {
      return _buildOfflineData(ref, range);
    }
  } else {
    return _buildOfflineData(ref, range);
  }
});

final _cashiersProvider = FutureProvider<List<dynamic>>((ref) async {
  final syncState = ref.watch(syncStateProvider);
  if (!syncState.isOnline) return [];
  try {
    final api = ref.read(apiClientProvider);
    return await api.getUsers();
  } catch (_) {
    return [];
  }
});

String _fmtIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<_ReportData> _buildOfflineData(Ref ref, DateTimeRange range) async {
  try {
    final localDb = ref.read(localDbServiceProvider);
    final localOrders = await localDb.getOrdersInDateRange(
      range.start,
      range.end,
    );
    if (localOrders.isEmpty) {
      return _ReportData(orders: _mockOrders, isOffline: true);
    }
    return _ReportData(orders: localOrders, isOffline: true);
  } catch (_) {
    return _ReportData(orders: _mockOrders, isOffline: true);
  }
}

Map<String, dynamic> _normalizeOrder(dynamic o) {
  final map = o as Map<String, dynamic>;
  if (map.containsKey('order')) {
    final orderMap = Map<String, dynamic>.from(
      map['order'] as Map<String, dynamic>,
    );
    if (map.containsKey('details')) {
      orderMap['details'] = map['details'];
    }
    if (map.containsKey('member')) {
      orderMap['member'] = map['member'];
    }
    return orderMap;
  }
  return map;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late DateTimeRange _dateRange;
  String _selectedStatus =
      'all'; // 'all', 'paid', 'unpaid', 'cancelled', 'active'
  String _selectedCashier = 'all'; // 'all' or userId

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: now,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _printReport(
    BuildContext context,
    List<dynamic> orders,
    List<dynamic> users,
  ) {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có dữ liệu báo cáo để in'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final filtered = orders.map((o) => _normalizeOrder(o)).where((o) {
      if (_selectedStatus != 'all' && o['status'] != _selectedStatus) {
        return false;
      }
      if (_selectedCashier != 'all') {
        final creator = o['created_by']?.toString() ?? '';
        final closer = o['closed_by']?.toString() ?? '';
        if (creator != _selectedCashier && closer != _selectedCashier) {
          return false;
        }
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có dữ liệu phù hợp với bộ lọc để in'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double totalPlay = filtered.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['total_play_time_amount']),
    );
    final double totalService = filtered.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['total_product_amount']),
    );
    final double totalDiscount = filtered.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['discount_amount']),
    );
    final double totalAmount = filtered.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['total_amount']),
    );

    final container = ProviderScope.containerOf(context);
    showDialog(
      context: context,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: ReportPrintPreviewDialog(
          dateRange: _dateRange,
          statusFilterLabel: _getStatusLabel(_selectedStatus),
          cashierFilterLabel: _selectedCashier == 'all'
              ? 'Tất cả nhân viên'
              : _getCashierName(_selectedCashier, users),
          totalInvoices: filtered.length,
          totalPlay: totalPlay,
          totalService: totalService,
          totalDiscount: totalDiscount,
          totalAmount: totalAmount,
          orders: filtered,
          showInvoiceList: _tabCtrl.index == 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final reportAsync = ref.watch(_reportDataProvider(_dateRange));
    final cashiersAsync = ref.watch(_cashiersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Báo cáo', style: AppTextStyles.headlineLarge),
                      Text(
                        'Phân tích dữ liệu chi tiết theo khoảng thời gian.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Offline badge
                  if (!syncState.isOnline)
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Offline – dữ liệu cục bộ',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Date range picker
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (result != null) {
                        setState(() => _dateRange = result);
                      }
                    },
                    icon: const Icon(Icons.date_range_outlined, size: 16),
                    label: Text(
                      '${_fmtDate(_dateRange.start)} – ${_fmtDate(_dateRange.end)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Refresh button
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(_reportDataProvider(_dateRange));
                      ref.invalidate(_cashiersProvider);
                    },
                    icon: const Icon(Icons.refresh_outlined, size: 16),
                    label: const Text('Làm mới'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filters & Print Row
              Row(
                children: [
                  // Status filter dropdown
                  Container(
                    width: 180,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: AppTextStyles.bodyMedium,
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tất cả trạng thái'),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Đã thanh toán'),
                          ),
                          DropdownMenuItem(
                            value: 'unpaid',
                            child: Text('Không thanh toán'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Đang phục vụ'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Đã hủy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cashier filter dropdown
                  Container(
                    width: 200,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: cashiersAsync.when(
                        loading: () => const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => const Text('Lỗi tải nhân viên'),
                        data: (users) {
                          final Map<String, String> cashierMap = {
                            'all': 'Tất cả nhân viên',
                          };
                          for (final u in users) {
                            final map = u as Map<String, dynamic>;
                            final id = map['id']?.toString() ?? '';
                            final name =
                                map['display_name'] as String? ??
                                map['username'] as String? ??
                                id;
                            if (id.isNotEmpty) cashierMap[id] = name;
                          }
                          cashierMap.putIfAbsent('system', () => 'Hệ thống');

                          if (!cashierMap.containsKey(_selectedCashier)) {
                            _selectedCashier = 'all';
                          }

                          return DropdownButton<String>(
                            value: _selectedCashier,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: AppTextStyles.bodyMedium,
                            onChanged: (String? val) {
                              if (val != null) {
                                setState(() => _selectedCashier = val);
                              }
                            },
                            items: cashierMap.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Print report button
                  OutlinedButton.icon(
                    onPressed: () {
                      _printReport(
                        context,
                        reportAsync.value?.orders ?? [],
                        cashiersAsync.value ?? [],
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('In báo cáo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.titleMedium,
                tabs: const [
                  Tab(text: 'Chi tiết hóa đơn'),
                  Tab(text: 'Tổng hợp hóa đơn'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: reportAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu báo cáo...'),
                ],
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không thể tải báo cáo',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(e.toString(), style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(_reportDataProvider(_dateRange));
                      ref.invalidate(_cashiersProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            data: (data) {
              // Apply filters to orders
              final filteredOrders = data.orders
                  .map((o) => _normalizeOrder(o))
                  .where((o) {
                    if (_selectedStatus != 'all' &&
                        o['status'] != _selectedStatus) {
                      return false;
                    }
                    if (_selectedCashier != 'all') {
                      final creator = o['created_by']?.toString() ?? '';
                      final closer = o['closed_by']?.toString() ?? '';
                      if (creator != _selectedCashier &&
                          closer != _selectedCashier) {
                        return false;
                      }
                    }
                    return true;
                  })
                  .toList();

              final users = cashiersAsync.value ?? [];

              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _InvoiceDetailsListTab(
                    orders: filteredOrders,
                    users: users,
                    isOffline: data.isOffline,
                  ),
                  _InvoiceSummaryTab(
                    orders: filteredOrders,
                    isOffline: data.isOffline,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Detailed Invoice List ──────────────────────────────────────────────

class _InvoiceDetailsListTab extends StatelessWidget {
  final List<dynamic> orders;
  final List<dynamic> users;
  final bool isOffline;

  const _InvoiceDetailsListTab({
    required this.orders,
    required this.users,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text('Không có hóa đơn phù hợp với bộ lọc'),
          ],
        ),
      );
    }

    final double totalDiscount = orders.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['discount_amount']),
    );
    final double totalAmount = orders.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['total_amount']),
    );
    final int totalMinutes = orders.fold(
      0,
      (sum, o) => sum + _toInt(o['total_play_time_minutes']),
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (isOffline) _OfflineNotice(),
          if (isOffline) const SizedBox(height: 12),
          // Metric Cards
          Row(
            children: [
              _ReportCard('Số hóa đơn', '${orders.length} HĐ', AppColors.info),
              const SizedBox(width: 12),
              _ReportCard(
                'Tổng giờ chơi',
                _fmtDuration(totalMinutes),
                AppColors.accent,
              ),
              const SizedBox(width: 12),
              _ReportCard(
                'Tổng chiết khấu',
                _fmtCurrency(totalDiscount),
                AppColors.error,
              ),
              const SizedBox(width: 12),
              _ReportCard(
                'Tổng doanh thu',
                _fmtCurrency(totalAmount),
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: AppColors.background,
                    child: const Row(
                      children: [
                        _TH('Mã HD', flex: 2),
                        _TH('Ngày', flex: 2),
                        _TH('Thu ngân', flex: 2),
                        _TH('Bàn chơi', flex: 2),
                        _TH('Giờ vào', flex: 1),
                        _TH('Giờ ra', flex: 1),
                        _TH('Tiền giờ', flex: 2),
                        _TH('Dịch vụ', flex: 2),
                        _TH('Khuyến mãi', flex: 2),
                        _TH('Tổng tiền', flex: 2),
                        _TH('Trạng thái', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final order = orders[i];
                        final idStr = order['id']?.toString() ?? '';
                        final shortId = idStr.length > 6
                            ? idStr.substring(idStr.length - 6)
                            : idStr;
                        final status = order['status']?.toString() ?? '';
                        final cashier = _getCashierName(
                          order['closed_by']?.toString() ??
                              order['created_by']?.toString(),
                          users,
                        );

                        // Format ngày thanh toán (dựa trên end_time hoặc created_at)
                        final payDateStr =
                            (order['end_time'] ?? order['created_at'] ?? '')
                                .toString();
                        String formattedPayDate = 'N/A';
                        if (payDateStr.isNotEmpty) {
                          try {
                            final dt = DateTime.parse(
                              payDateStr.replaceAll(' ', 'T'),
                            );
                            formattedPayDate =
                                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                          } catch (_) {}
                        }

                        // Giờ vào / giờ ra
                        final startStr = order['start_time']?.toString() ?? '';
                        final endStr = order['end_time']?.toString() ?? '';
                        String startTimeText = '--:--';
                        String endTimeText = '--:--';
                        if (startStr.isNotEmpty) {
                          try {
                            final dt = DateTime.parse(
                              startStr.replaceAll(' ', 'T'),
                            );
                            startTimeText =
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          } catch (_) {}
                        }
                        if (endStr.isNotEmpty) {
                          try {
                            final dt = DateTime.parse(
                              endStr.replaceAll(' ', 'T'),
                            );
                            endTimeText =
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                          } catch (_) {}
                        }

                        final playAmount = _toDouble(
                          order['total_play_time_amount'],
                        );
                        final serviceAmount = _toDouble(
                          order['total_product_amount'],
                        );
                        final discountAmount = _toDouble(
                          order['discount_amount'],
                        );
                        final totalAmount = _toDouble(order['total_amount']);

                        return InkWell(
                          onTap: () {
                            showDialog(
                              context: ctx,
                              builder: (_) => _InvoiceDetailsDialog(
                                order: order,
                                users: users,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '#$shortId',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formattedPayDate,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    cashier,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    order['table_name']?.toString() ?? 'N/A',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    startTimeText,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    endTimeText,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmtCurrency(playAmount),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmtCurrency(serviceAmount),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmtCurrency(discountAmount),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmtCurrency(totalAmount),
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusLabel(status),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Grouped Daily Invoice Summary ──────────────────────────────────────

class _InvoiceSummaryTab extends StatelessWidget {
  final List<dynamic> orders;
  final bool isOffline;

  const _InvoiceSummaryTab({required this.orders, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    // Group orders by day
    final Map<String, List<Map<String, dynamic>>> byDay = {};
    for (final o in orders) {
      final raw = o as Map<String, dynamic>;

      final dateStr = (raw['created_at'] as String? ?? '').replaceAll(' ', 'T');
      DateTime? dt;
      try {
        if (dateStr.isNotEmpty) dt = DateTime.parse(dateStr);
      } catch (_) {}
      if (dt == null) continue;

      final key =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      byDay.putIfAbsent(key, () => []).add(raw);
    }

    final rows = byDay.entries.map((e) {
      final list = e.value;
      double play = 0, service = 0, total = 0;
      for (final r in list) {
        play += _toDouble(r['total_play_time_amount']);
        service += _toDouble(r['total_product_amount']);
        total += _toDouble(r['total_amount']);
      }
      return _ReportRow(
        date: e.key,
        count: list.length,
        play: play,
        service: service,
        total: total,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    if (rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text('Không có dữ liệu tổng hợp cho khoảng thời gian này'),
          ],
        ),
      );
    }

    final grandTotal = rows.fold(0.0, (s, r) => s + r.total);
    final totalCount = rows.fold(0, (s, r) => s + r.count);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (isOffline) _OfflineNotice(),
          if (isOffline) const SizedBox(height: 12),
          // Summary cards
          Row(
            children: [
              _ReportCard('Tổng hóa đơn', '$totalCount HĐ', AppColors.info),
              const SizedBox(width: 12),
              _ReportCard(
                'Tổng doanh thu',
                _fmtCurrency(grandTotal),
                AppColors.success,
              ),
              const SizedBox(width: 12),
              _ReportCard(
                'TB hàng ngày',
                _fmtCurrency(rows.isNotEmpty ? grandTotal / rows.length : 0),
                AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: AppColors.background,
                    child: const Row(
                      children: [
                        _TH('Ngày', flex: 2),
                        _TH('Số HĐ', flex: 1),
                        _TH('Tiền giờ', flex: 2),
                        _TH('Dịch vụ', flex: 2),
                        _TH('Tổng', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  r.date,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${r.count} HĐ',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _fmtCurrency(r.play),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _fmtCurrency(r.service),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _fmtCurrency(r.total),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog: Invoice Detailed View ─────────────────────────────────────────────

class _InvoiceDetailsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  final List<dynamic> users;

  const _InvoiceDetailsDialog({required this.order, required this.users});

  @override
  ConsumerState<_InvoiceDetailsDialog> createState() =>
      _InvoiceDetailsDialogState();
}

class _InvoiceDetailsDialogState extends ConsumerState<_InvoiceDetailsDialog> {
  bool _isLoading = false;
  List<dynamic> _details = [];
  Map<String, dynamic>? _member;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (widget.order.containsKey('details') &&
        widget.order['details'] is List) {
      setState(() {
        _details = widget.order['details'] as List<dynamic>;
        _member = widget.order['member'] as Map<String, dynamic>?;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getOrderDetails(widget.order['id']);
      if (mounted) {
        setState(() {
          _details = res['data']?['details'] as List<dynamic>? ?? [];
          _member = res['data']?['member'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải chi tiết hóa đơn từ máy chủ: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _fmtTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _printInvoice(BuildContext context) {
    final order = widget.order;
    final status = order['status']?.toString() ?? 'paid';
    final cashier = _getCashierName(
      order['closed_by']?.toString() ?? order['created_by']?.toString(),
      widget.users,
    );

    DateTime _parseDate(String? s) {
      if (s == null || s.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(s.replaceAll(' ', 'T'));
      } catch (_) {
        return DateTime.now();
      }
    }

    final startTime = _parseDate(order['start_time']?.toString());
    final endTime = _parseDate(order['end_time']?.toString());
    final playMinutes = _toInt(order['total_play_time_minutes']);
    final playAmount = _toDouble(order['total_play_time_amount']);
    final hourlyRate = _toDouble(order['hourly_rate'] ?? order['price_per_hour']);
    final totalAmount = _toDouble(order['total_play_time_amount']) +
        _toDouble(order['total_product_amount']);
    final discountAmount = _toDouble(order['discount_amount']);
    final discountPercent = _toDouble(order['discount_percent']);
    final netTotal = _toDouble(order['total_amount']);

    // Build products list from _details
    final products = _details.map((d) {
      return <String, dynamic>{
        'name': d['product_name']?.toString() ?? 'Sản phẩm',
        'qty': _toInt(d['quantity']),
        'price': _toDouble(d['total_price']) /
            (_toInt(d['quantity']) == 0 ? 1 : _toInt(d['quantity'])),
      };
    }).toList();

    final container = ProviderScope.containerOf(context);
    showDialog(
      context: context,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: InvoicePrintPreviewDialog(
          tableName: order['table_name']?.toString() ?? 'Bàn',
          startTime: startTime,
          endTime: endTime,
          playMinutes: playMinutes,
          playAmount: playAmount,
          hourlyRate: hourlyRate,
          products: products,
          totalAmount: totalAmount,
          discountPercent: discountPercent,
          discountAmount: discountAmount,
          netTotal: netTotal,
          member: _member,
          cashierName: cashier,
          shiftLabel: null,
          status: status == 'unpaid' ? 'unpaid' : 'paid',
          note: order['note']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortId = order['id']?.toString() ?? '';
    final shortIdDisplay = shortId.length > 6
        ? shortId.substring(shortId.length - 6)
        : shortId;
    final status = order['status']?.toString() ?? '';
    final cashier = _getCashierName(
      order['closed_by']?.toString() ?? order['created_by']?.toString(),
      widget.users,
    );
    final note = order['note']?.toString();

    final playAmount = _toDouble(order['total_play_time_amount']);
    final serviceAmount = _toDouble(order['total_product_amount']);
    final totalDiscount = _toDouble(order['discount_amount']);
    final taxAmount = _toDouble(order['tax_amount']);
    final finalAmount = _toDouble(order['total_amount']);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHI TIẾT HÓA ĐƠN #$shortIdDisplay',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          order['table_name']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Đang tải chi tiết hóa đơn...'),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Time & Status Info
                          _InfoRow(
                            'Giờ vào',
                            _fmtTime(order['start_time']?.toString()),
                            Icons.login,
                          ),
                          _InfoRow(
                            'Giờ ra',
                            _fmtTime(order['end_time']?.toString()),
                            Icons.logout,
                          ),
                          _InfoRow(
                            'Thời lượng',
                            _fmtDuration(
                              _toInt(order['total_play_time_minutes']),
                            ),
                            Icons.timer_outlined,
                          ),
                          _InfoRow('Thu ngân', cashier, Icons.person_outline),
                          const SizedBox(height: 12),

                          // Member section
                          if (_member != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.stars,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Thành viên: ${_member!['full_name'] ?? _member!['name'] ?? ''} (${_member!['tier'] ?? _member!['tier_name'] ?? ''})',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Status Badge Box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(status).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _getStatusColor(status),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Trạng thái: ',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _getStatusLabel(status),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(status),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 24),

                          // Products and Services
                          if (_details.isNotEmpty) ...[
                            Text(
                              'Dịch vụ / Sản phẩm:',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            ..._details.map((d) {
                              final name =
                                  d['product_name']?.toString() ?? 'Sản phẩm';
                              final qty = _toInt(d['quantity']);
                              final unit = d['unit']?.toString() ?? '';
                              final unitStr = unit.isNotEmpty ? ' $unit' : '';
                              final total = _toDouble(d['total_price']);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$name × $qty$unitStr',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ),
                                    Text(
                                      _fmtCurrency(total),
                                      style: AppTextStyles.labelLarge,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 24),
                          ],

                          // Prices Summary
                          Row(
                            children: [
                              const Text(
                                'Tiền giờ chơi',
                                style: AppTextStyles.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                _fmtCurrency(playAmount),
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                          if (serviceAmount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  'Tiền dịch vụ',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const Spacer(),
                                Text(
                                  _fmtCurrency(serviceAmount),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                          if (totalDiscount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  'Chiết khấu / Giảm giá',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '-${_fmtCurrency(totalDiscount)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (taxAmount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  'Thuế',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const Spacer(),
                                Text(
                                  _fmtCurrency(taxAmount),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Text(
                                'TỔNG CỘNG',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _fmtCurrency(finalAmount),
                                style: AppTextStyles.currency,
                              ),
                            ],
                          ),

                          // Note / Reason
                          if (status == 'cancelled' || status == 'unpaid') ...[
                            const Divider(height: 24),
                            Text(
                              status == 'cancelled'
                                  ? 'Lý do hủy bàn:'
                                  : 'Lý do không thanh toán:',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (note != null && note.trim().isNotEmpty)
                                    ? note
                                    : 'Không có lý do được ghi nhận',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ] else if (note != null &&
                              note.trim().isNotEmpty) ...[
                            const Divider(height: 24),
                            Text('Ghi chú:', style: AppTextStyles.titleMedium),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                note,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            // Footer Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printInvoice(context),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('In hóa đơn'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers & Utilities ───────────────────────────────────────────────────────

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

String _fmtDuration(int minutes) {
  if (minutes < 60) return '$minutes phút';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '$h giờ';
  return '$h giờ $m phút';
}

String _getCashierName(String? userId, List<dynamic> users) {
  if (userId == null || userId.isEmpty) return 'N/A';
  if (userId == 'system') return 'Hệ thống';
  final user = users.firstWhere(
    (u) => (u as Map<String, dynamic>)['id']?.toString() == userId,
    orElse: () => null,
  );
  if (user != null) {
    final displayName = user['display_name'] as String?;
    final username = user['username'] as String?;
    if (displayName != null && displayName.isNotEmpty) return displayName;
    if (username != null && username.isNotEmpty) return username;
  }
  return userId;
}

String _getStatusLabel(String status) {
  switch (status) {
    case 'all':
      return 'Tất cả';
    case 'paid':
      return 'Đã thanh toán';
    case 'unpaid':
      return 'Không thanh toán';
    case 'active':
      return 'Đang phục vụ';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return status;
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'unpaid':
      return AppColors.error;
    case 'active':
      return AppColors.primary;
    case 'cancelled':
      return AppColors.textMuted;
    default:
      return AppColors.textSecondary;
  }
}

// ─── Offline Notice ───────────────────────────────────────────────────────────

class _OfflineNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accent.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Đang hiển thị dữ liệu cục bộ (offline). Kết nối mạng để lấy dữ liệu mới nhất.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
          ),
        ),
      ],
    ),
  );
}

// ─── Shared Report Widgets ────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ReportCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}
