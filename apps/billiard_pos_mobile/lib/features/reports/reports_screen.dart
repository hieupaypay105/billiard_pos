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
  final double discount;
  final double total;

  const _ReportRow({
    required this.date,
    required this.count,
    required this.play,
    required this.service,
    required this.discount,
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

class _SummaryParam {
  final DateTimeRange range;
  final String status;
  final String cashier;

  const _SummaryParam({
    required this.range,
    required this.status,
    required this.cashier,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SummaryParam &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          status == other.status &&
          cashier == other.cashier;

  @override
  int get hashCode => range.hashCode ^ status.hashCode ^ cashier.hashCode;
}

final _dailySummaryProvider = FutureProvider.family<List<dynamic>, _SummaryParam>((
  ref,
  param,
) async {
  final syncState = ref.watch(syncStateProvider);
  final isOnline = syncState.isOnline;

  if (isOnline) {
    try {
      final api = ref.read(apiClientProvider);
      final dateFrom = _fmtIso(param.range.start);
      final dateTo = _fmtIso(param.range.end);
      return await api.getDailySummary(
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: param.status != 'all' ? param.status : null,
        cashierId: param.cashier != 'all' ? param.cashier : null,
      );
    } catch (e) {
      debugPrint('Error fetching daily summary from API: $e');
      return [];
    }
  }
  return [];
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

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late DateTimeRange _dateRange;
  String _selectedStatus = 'all'; // 'all', 'paid', 'unpaid', 'cancelled', 'active'
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Báo cáo doanh thu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(_reportDataProvider(_dateRange));
              ref.invalidate(_cashiersProvider);
            },
            tooltip: 'Làm mới',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _printReport(
            context,
            reportAsync.value?.orders ?? [],
            cashiersAsync.value ?? [],
          );
        },
        icon: const Icon(Icons.print),
        label: const Text('In báo cáo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Date range picker row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Dropdown filters row
                Row(
                  children: [
                    // Status filter dropdown
                    Expanded(
                      child: Container(
                        height: 38,
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
                            style: const TextStyle(fontSize: 12.5, color: Colors.black87, fontFamily: 'Inter'),
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
                    ),
                    const SizedBox(width: 8),
                    // Cashier filter dropdown
                    Expanded(
                      child: Container(
                        height: 38,
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
                            error: (err, stack) => const Text('Lỗi tải nhân viên', style: TextStyle(fontSize: 12)),
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
                                style: const TextStyle(fontSize: 12.5, color: Colors.black87, fontFamily: 'Inter'),
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
                    ),
                  ],
                ),
                if (!syncState.isOnline) ...[
                  const SizedBox(height: 8),
                  _OfflineNotice(),
                ],
              ],
            ),
          ),
          
          // Tab bar indicators
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Chi tiết hóa đơn'),
                Tab(text: 'Tổng hợp hóa đơn'),
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
                    Text(e.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
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
                      dateRange: _dateRange,
                      status: _selectedStatus,
                      cashier: _selectedCashier,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Detailed Invoice List (Mobile Optimized) ─────────────────────────

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
    final double totalPlayAmount = orders.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['total_play_time_amount']),
    );
    final double totalServiceAmount = orders.fold(
      0.0,
      (sum, o) => sum + _toDouble(o['total_product_amount']),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Total Revenue Header (Dashboard Style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TỔNG DOANH THU',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _fmtCurrency(totalAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Metrics 2x2 Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            _buildGridMetricCard('Số hóa đơn', '${orders.length} HĐ', AppColors.info),
            _buildGridMetricCard('Tiền giờ chơi', _fmtCurrency(totalPlayAmount), AppColors.accent),
            _buildGridMetricCard('Tiền dịch vụ', _fmtCurrency(totalServiceAmount), AppColors.warning),
            _buildGridMetricCard('Chiết khấu', '-${_fmtCurrency(totalDiscount)}', AppColors.error),
          ],
        ),
        const SizedBox(height: 18),
        // Invoice list title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DANH SÁCH CHI TIẾT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
            ),
            Text('${orders.length} giao dịch', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        // Invoice Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final order = orders[idx];
            final idStr = order['id']?.toString() ?? '';
            final shortId = idStr.length > 6 ? idStr.substring(idStr.length - 6) : idStr;
            final status = order['status']?.toString() ?? '';
            final cashier = _getCashierName(
              order['closed_by']?.toString() ?? order['created_by']?.toString(),
              users,
            );
            
            DateTime parseDate(String? s) {
              if (s == null || s.isEmpty) return DateTime.now();
              try { return DateTime.parse(s.replaceAll(' ', 'T')); } catch (_) { return DateTime.now(); }
            }
            final closedAt = parseDate(order['end_time'] ?? order['created_at']);
            final amountStr = _fmtCurrency(_toDouble(order['total_amount']));

            return InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => UncontrolledProviderScope(
                    container: ProviderScope.containerOf(context),
                    child: _InvoiceDetailsDialog(order: order, users: users),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Left Status Badge
                    Container(
                      width: 5,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order['table_name']?.toString() ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusLabel(status),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(status),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã: #$shortId · TN: $cashier',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Giờ: ${_fmtTime(order['start_time'])} - ${_fmtTime(order['end_time'])}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountStr,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: status == 'unpaid' ? AppColors.error : AppColors.primary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${closedAt.day}/${closedAt.month}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: color, fontFamily: 'Inter'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Grouped Daily Invoice Summary (Mobile Optimized) ─────────────────

class _InvoiceSummaryTab extends ConsumerWidget {
  final List<dynamic> orders;
  final bool isOffline;
  final DateTimeRange dateRange;
  final String status;
  final String cashier;

  const _InvoiceSummaryTab({
    required this.orders,
    required this.isOffline,
    required this.dateRange,
    required this.status,
    required this.cashier,
  });

  List<_ReportRow> _groupOrdersInMemory(List<dynamic> ordersList) {
    final Map<String, List<Map<String, dynamic>>> byDay = {};
    for (final o in ordersList) {
      final raw = o as Map<String, dynamic>;

      final dateStr = (raw['created_at'] as String? ?? '').replaceAll(' ', 'T');
      DateTime? dt;
      try {
        if (dateStr.isNotEmpty) dt = DateTime.parse(dateStr).subtract(const Duration(hours: 8));
      } catch (_) {}
      if (dt == null) continue;

      final key =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      byDay.putIfAbsent(key, () => []).add(raw);
    }

    return byDay.entries.map((e) {
      final list = e.value;
      double play = 0, service = 0, discount = 0, total = 0;
      for (final r in list) {
        play += _toDouble(r['total_play_time_amount']);
        service += _toDouble(r['total_product_amount']);
        discount += _toDouble(r['discount_amount']);
        total += _toDouble(r['total_amount']);
      }
      return _ReportRow(
        date: e.key,
        count: list.length,
        play: play,
        service: service,
        discount: discount,
        total: total,
      );
    }).toList()..sort((a, b) {
      try {
        final aParts = a.date.split('/');
        final bParts = b.date.split('/');
        if (aParts.length == 3 && bParts.length == 3) {
          final aDate = DateTime(int.parse(aParts[2]), int.parse(aParts[1]), int.parse(aParts[0]));
          final bDate = DateTime(int.parse(bParts[2]), int.parse(bParts[1]), int.parse(bParts[0]));
          return bDate.compareTo(aDate);
        }
      } catch (_) {}
      return b.date.compareTo(a.date);
    });
  }

  Widget _renderRows(BuildContext context, List<_ReportRow> rows) {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Total summary metrics row
        Row(
          children: [
            Expanded(
              child: _buildGridSummaryCard('Doanh thu', _fmtCurrency(grandTotal), AppColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGridSummaryCard('Số HĐ', '$totalCount HĐ', AppColors.info),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Title
        const Text(
          'TỔNG HỢP THEO NGÀY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        // Grouped list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = rows[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.date,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, fontFamily: 'Inter'),
                      ),
                      Text(
                        '${r.count} hóa đơn',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildDailyItemRow('Tiền giờ chơi', _fmtCurrency(r.play)),
                  const SizedBox(height: 6),
                  _buildDailyItemRow('Dịch vụ', _fmtCurrency(r.service)),
                  if (r.discount > 0) ...[
                    const SizedBox(height: 6),
                    _buildDailyItemRow('Chiết khấu', '-${_fmtCurrency(r.discount)}', isDiscount: true),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter'),
                      ),
                      Text(
                        _fmtCurrency(r.total),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildDailyItemRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDiscount ? AppColors.accent : AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDiscount ? AppColors.accent : AppColors.textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOffline) {
      final inMemoryRows = _groupOrdersInMemory(orders);
      return _renderRows(context, inMemoryRows);
    }

    final param = _SummaryParam(range: dateRange, status: status, cashier: cashier);
    final summaryAsync = ref.watch(_dailySummaryProvider(param));

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) {
        debugPrint('Daily summary error: $e, falling back to local memory calculation');
        final inMemoryRows = _groupOrdersInMemory(orders);
        return _renderRows(context, inMemoryRows);
      },
      data: (summaryData) {
        if (summaryData.isEmpty) {
          if (orders.isNotEmpty) {
            final inMemoryRows = _groupOrdersInMemory(orders);
            return _renderRows(context, inMemoryRows);
          }
        }

        final List<_ReportRow> rows = [];
        for (final item in summaryData) {
          if (item is! Map<String, dynamic>) continue;

          final dateRaw = (item['date'] ?? item['order_date'] ?? item['date_group'] ?? item['created_at'] ?? '').toString();
          String formattedDate = dateRaw;
          try {
            if (dateRaw.contains('-')) {
              final dt = DateTime.parse(dateRaw.replaceAll(' ', 'T'));
              formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            }
          } catch (_) {}

          final countVal = item['count'] ?? item['order_count'] ?? item['total_invoices'] ?? 0;
          final playVal = item['play'] ?? item['play_amount'] ?? item['total_play_time_amount'] ?? 0.0;
          final serviceVal = item['service'] ?? item['product_amount'] ?? item['service_amount'] ?? item['total_product_amount'] ?? 0.0;
          final discountVal = item['discount'] ?? item['discount_amount'] ?? 0.0;
          final totalVal = item['total'] ?? item['daily_revenue'] ?? item['total_amount'] ?? item['grand_total'] ?? 0.0;

          rows.add(_ReportRow(
            date: formattedDate,
            count: _toInt(countVal),
            play: _toDouble(playVal),
            service: _toDouble(serviceVal),
            discount: _toDouble(discountVal),
            total: _toDouble(totalVal),
          ));
        }

        // Sort descending by date
        rows.sort((a, b) {
          try {
            final aParts = a.date.split('/');
            final bParts = b.date.split('/');
            if (aParts.length == 3 && bParts.length == 3) {
              final aDate = DateTime(int.parse(aParts[2]), int.parse(aParts[1]), int.parse(aParts[0]));
              final bDate = DateTime(int.parse(bParts[2]), int.parse(bParts[1]), int.parse(bParts[0]));
              return bDate.compareTo(aDate);
            }
          } catch (_) {}
          return b.date.compareTo(a.date);
        });

        return _renderRows(context, rows);
      },
    );
  }
}

// ─── Dialog: Invoice Detailed View (Mobile Optimized Modal) ──────────────────

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

  void _printInvoice(BuildContext context) {
    final order = widget.order;
    final status = order['status']?.toString() ?? 'paid';
    final cashier = _getCashierName(
      order['closed_by']?.toString() ?? order['created_by']?.toString(),
      widget.users,
    );

    DateTime parseDate(String? s) {
      if (s == null || s.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(s.replaceAll(' ', 'T'));
      } catch (_) {
        return DateTime.now();
      }
    }

    final startTime = parseDate(order['start_time']?.toString());
    final endTime = parseDate(order['end_time']?.toString());
    final playMinutes = _toInt(order['total_play_time_minutes']);
    final playAmount = _toDouble(order['total_play_time_amount']);
    final hourlyRate = _toDouble(order['hourly_rate'] ?? order['price_per_hour']);
    final totalAmount = _toDouble(order['total_play_time_amount']) +
        _toDouble(order['total_product_amount']);
    final discountAmount = _toDouble(order['discount_amount']);
    final discountPercent = _toDouble(order['discount_percent']);
    final netTotal = _toDouble(order['total_amount']);

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
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHI TIẾT HÓA ĐƠN #$shortIdDisplay',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          order['table_name']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Time & Status Info
                          _buildDetailRow('Giờ vào', _fmtTime(order['start_time']?.toString()), Icons.login),
                          _buildDetailRow('Giờ ra', _fmtTime(order['end_time']?.toString()), Icons.logout),
                          _buildDetailRow(
                            'Thời lượng',
                            _fmtDuration(_toInt(order['total_play_time_minutes'])),
                            Icons.timer_outlined,
                          ),
                          _buildDetailRow('Thu ngân', cashier, Icons.person_outline),
                          const SizedBox(height: 10),

                          // Member section
                          if (_member != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.success.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.stars, color: AppColors.success, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Thành viên: ${_member!['full_name'] ?? _member!['name'] ?? ''} (${_member!['tier'] ?? _member!['tier_name'] ?? ''})',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Status Badge Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: _getStatusColor(status), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Trạng thái: ',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                                ),
                                Text(
                                  _getStatusLabel(status),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(status),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 20),

                          // Products and Services
                          if (_details.isNotEmpty) ...[
                            const Text(
                              'Dịch vụ / Sản phẩm:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter'),
                            ),
                            const SizedBox(height: 4),
                            ..._details.map((d) {
                              final name = d['product_name']?.toString() ?? 'Sản phẩm';
                              final qty = _toInt(d['quantity']);
                              final unit = d['unit']?.toString() ?? '';
                              final unitStr = unit.isNotEmpty ? ' $unit' : '';
                              final total = _toDouble(d['total_price']);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$name × $qty$unitStr',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                                      ),
                                    ),
                                    Text(
                                      _fmtCurrency(total),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'Inter'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 20),
                          ],

                          // Prices Summary
                          _buildSummaryRow('Tiền giờ chơi', _fmtCurrency(playAmount)),
                          if (serviceAmount > 0) ...[
                            const SizedBox(height: 4),
                            _buildSummaryRow('Tiền dịch vụ', _fmtCurrency(serviceAmount)),
                          ],
                          if (totalDiscount > 0) ...[
                            const SizedBox(height: 4),
                            _buildSummaryRow('Chiết khấu / Giảm giá', '-${_fmtCurrency(totalDiscount)}', isDiscount: true),
                          ],
                          if (taxAmount > 0) ...[
                            const SizedBox(height: 4),
                            _buildSummaryRow('Thuế', _fmtCurrency(taxAmount)),
                          ],
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Text(
                                'TỔNG CỘNG',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _fmtCurrency(finalAmount),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          // Note / Reason
                          if (status == 'cancelled' || status == 'unpaid') ...[
                            const Divider(height: 20),
                            Text(
                              status == 'cancelled' ? 'Lý do hủy bàn:' : 'Lý do không thanh toán:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter'),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (note != null && note.trim().isNotEmpty) ? note : 'Không có lý do được ghi nhận',
                                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontFamily: 'Inter'),
                              ),
                            ),
                          ] else if (note != null && note.trim().isNotEmpty) ...[
                            const Divider(height: 20),
                            const Text('Ghi chú:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter')),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                note,
                                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontFamily: 'Inter'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            // Footer Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printInvoice(context),
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('In hóa đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Đóng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: isDiscount ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDiscount ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Helpers & Utilities ───────────────────────────────────────────────────────

String _fmtTime(dynamic s) {
  if (s == null) return '--:--';
  final dateStr = s.toString().trim();
  if (dateStr.isEmpty) return '--:--';
  try {
    final dt = DateTime.parse(dateStr.replaceAll(' ', 'T'));
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return dateStr;
  }
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Báo cáo chạy ngoại tuyến (offline). Kết nối mạng để cập nhật.',
            style: const TextStyle(fontSize: 10.5, color: AppColors.accent, fontFamily: 'Inter'),
          ),
        ),
      ],
    ),
  );
}
