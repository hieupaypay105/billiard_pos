import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/providers.dart';
import '../../features/sync/sync_provider.dart';

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

class _MemberRow {
  final String name;
  final String phone;
  final String tier;
  final int points;
  final double spend;

  const _MemberRow({
    required this.name,
    required this.phone,
    required this.tier,
    required this.points,
    required this.spend,
  });
}

class _ProductRow {
  final String name;
  final String category;
  final int sold;
  final int stock;
  final double revenue;

  const _ProductRow({
    required this.name,
    required this.category,
    required this.sold,
    required this.stock,
    required this.revenue,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────

class _ReportData {
  final List<_ReportRow> invoiceRows;
  final List<_MemberRow> memberRows;
  final List<_ProductRow> productRows;
  final bool isOffline;

  const _ReportData({
    this.invoiceRows = const [],
    this.memberRows = const [],
    this.productRows = const [],
    this.isOffline = false,
  });
}

// ─── Mock fallback data (khi offline & local DB rỗng) ────────────────────────

const _mockInvoiceRows = [
  _ReportRow(date: '22/05/2026', count: 12, play: 1200000, service: 450000, total: 1650000),
  _ReportRow(date: '21/05/2026', count: 9, play: 850000, service: 320000, total: 1170000),
  _ReportRow(date: '20/05/2026', count: 15, play: 1500000, service: 600000, total: 2100000),
  _ReportRow(date: '19/05/2026', count: 7, play: 620000, service: 210000, total: 830000),
  _ReportRow(date: '18/05/2026', count: 11, play: 980000, service: 390000, total: 1370000),
];

const _mockMemberRows = [
  _MemberRow(name: 'Nguyễn Văn Hùng', phone: '0901234567', tier: 'Gold', points: 1250, spend: 12500000),
  _MemberRow(name: 'Trần Thị Mai', phone: '0987654321', tier: 'Silver', points: 480, spend: 4800000),
  _MemberRow(name: 'Lê Văn Dũng', phone: '0912345678', tier: 'Diamond', points: 3200, spend: 32000000),
  _MemberRow(name: 'Phạm Minh Tuấn', phone: '0923456789', tier: 'Silver', points: 230, spend: 2300000),
];

const _mockProductRows = [
  _ProductRow(name: 'Sting Dâu Đỏ', category: 'Đồ uống', sold: 148, stock: 52, revenue: 2220000),
  _ProductRow(name: 'Bia Tiger', category: 'Đồ uống', sold: 95, stock: 35, revenue: 2850000),
  _ProductRow(name: 'Mì Xào Bò', category: 'Đồ ăn', sold: 62, stock: 0, revenue: 2170000),
  _ProductRow(name: 'Red Bull', category: 'Đồ uống', sold: 58, stock: 24, revenue: 1450000),
  _ProductRow(name: 'Thuốc Lá Marlboro', category: 'Thuốc lá', sold: 41, stock: 12, revenue: 1148000),
];

// ─── Provider ─────────────────────────────────────────────────────────────────

final _reportDataProvider = FutureProvider.family<_ReportData, DateTimeRange>(
  (ref, range) async {
    final syncState = ref.watch(syncStateProvider);
    final isOnline = syncState.isOnline;

    if (isOnline) {
      // Fetch từ API
      try {
        final api = ref.read(apiClientProvider);
        final dateFrom = _fmtIso(range.start);
        final dateTo = _fmtIso(range.end);

        // Dùng getAllOrders để lấy toàn bộ (hỗ trợ pagination)
        final List<dynamic> orders = await api.getAllOrders(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );

        final invoiceRows = _buildInvoiceRowsFromApi(orders, range);
        final memberRows = await _buildMemberRowsFromApi(api);
        final productRows = await _buildProductRowsFromApi(api, dateFrom, dateTo);

        return _ReportData(
          invoiceRows: invoiceRows,
          memberRows: memberRows,
          productRows: productRows,
          isOffline: false,
        );
      } catch (e) {
        // API lỗi → fallback sang local
        return _buildOfflineData(ref, range);
      }
    } else {
      return _buildOfflineData(ref, range);
    }
  },
);

String _fmtIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Xây dựng dữ liệu từ API orders – nhóm theo ngày
List<_ReportRow> _buildInvoiceRowsFromApi(List<dynamic> orders, DateTimeRange range) {
  if (orders.isEmpty) return [];

  // Nhóm orders theo ngày (dựa theo created_at)
  final Map<String, List<dynamic>> byDay = {};
  for (final o in orders) {
    final raw = o as Map<String, dynamic>;

    // Dùng created_at để nhóm theo ngày (format: "2026-06-05 14:51:06")
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

  return byDay.entries.map((e) {
    final rows = e.value;
    double play = 0, service = 0, total = 0;
    for (final r in rows) {
      // Tiền giờ chơi
      play += _toDouble(r['total_play_time_amount']);
      // Tiền sản phẩm / dịch vụ
      service += _toDouble(r['total_product_amount']);
      // Tổng thanh toán thực tế
      total += _toDouble(r['total_amount']);
    }
    return _ReportRow(
      date: e.key,
      count: rows.length,
      play: play,
      service: service,
      total: total,
    );
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}



Future<List<_MemberRow>> _buildMemberRowsFromApi(dynamic api) async {
  try {
    final members = await api.getMembers();
    return (members as List<dynamic>).map((m) {
      final r = m as Map<String, dynamic>;
      return _MemberRow(
        name: r['name'] as String? ?? r['full_name'] as String? ?? 'N/A',
        phone: r['phone_number'] as String? ?? r['phone'] as String? ?? '',
        tier: r['tier'] as String? ?? r['membership_tier'] as String? ?? 'Standard',
        points: _toInt(r['points'] ?? r['loyalty_points'] ?? 0),
        spend: _toDouble(r['total_spend'] ?? r['total_amount'] ?? r['spend'] ?? 0),
      );
    }).toList();
  } catch (_) {
    return _mockMemberRows;
  }
}

Future<List<_ProductRow>> _buildProductRowsFromApi(
    dynamic api, String dateFrom, String dateTo) async {
  try {
    final products = await api.getTopProducts(
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: 20,
    );
    return (products as List<dynamic>).map((p) {
      final r = p as Map<String, dynamic>;
      return _ProductRow(
        name: r['name'] as String? ?? r['product_name'] as String? ?? 'N/A',
        category: r['category'] as String? ?? r['category_name'] as String? ?? '',
        sold: _toInt(r['sold'] ?? r['quantity_sold'] ?? r['total_quantity'] ?? 0),
        stock: _toInt(r['stock'] ?? r['quantity_stock'] ?? r['stock_quantity'] ?? 0),
        revenue: _toDouble(r['revenue'] ?? r['total_revenue'] ?? r['total_amount'] ?? 0),
      );
    }).toList();
  } catch (_) {
    return _mockProductRows;
  }
}

/// Lấy dữ liệu từ local DB khi offline
Future<_ReportData> _buildOfflineData(Ref ref, DateTimeRange range) async {
  try {
    final localDb = ref.read(localDbServiceProvider);
    final localOrders = await localDb.getOrdersInDateRange(range.start, range.end);

    if (localOrders.isEmpty) {
      // Không có dữ liệu local → dùng mock data
      return const _ReportData(
        invoiceRows: _mockInvoiceRows,
        memberRows: _mockMemberRows,
        productRows: _mockProductRows,
        isOffline: true,
      );
    }

    final invoiceRows = _buildInvoiceRowsFromApi(localOrders, range);
    // Members & products không có local cache → dùng mock
    return _ReportData(
      invoiceRows: invoiceRows.isEmpty ? _mockInvoiceRows : invoiceRows,
      memberRows: _mockMemberRows,
      productRows: _mockProductRows,
      isOffline: true,
    );
  } catch (_) {
    return const _ReportData(
      invoiceRows: _mockInvoiceRows,
      memberRows: _mockMemberRows,
      productRows: _mockProductRows,
      isOffline: true,
    );
  }
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final reportAsync = ref.watch(_reportDataProvider(_dateRange));

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
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Báo cáo', style: AppTextStyles.headlineLarge),
                  Text('Phân tích dữ liệu chi tiết theo khoảng thời gian.',
                      style: AppTextStyles.bodySmall),
                ]),
                const Spacer(),
                // Offline badge
                if (!syncState.isOnline)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cloud_off_outlined, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text('Offline – dữ liệu cục bộ',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.error)),
                    ]),
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
                              primary: AppColors.primary)),
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
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                // Refresh button
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(_reportDataProvider(_dateRange));
                  },
                  icon: const Icon(Icons.refresh_outlined, size: 16),
                  label: const Text('Làm mới'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.titleMedium,
                tabs: const [
                  Tab(text: 'Hóa đơn'),
                  Tab(text: 'Thành viên'),
                  Tab(text: 'Sản phẩm/DV'),
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
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Không thể tải báo cáo', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(e.toString(), style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(_reportDataProvider(_dateRange)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            data: (data) => TabBarView(
              controller: _tabCtrl,
              children: [
                _InvoiceReportTab(rows: data.invoiceRows, isOffline: data.isOffline),
                _MemberReportTab(rows: data.memberRows),
                _ProductReportTab(products: data.productRows),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Invoice Report ────────────────────────────────────────────────────

class _InvoiceReportTab extends StatelessWidget {
  final List<_ReportRow> rows;
  final bool isOffline;
  const _InvoiceReportTab({required this.rows, required this.isOffline});

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
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Không có hóa đơn trong khoảng thời gian này'),
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
          // Offline notice
          if (isOffline) _OfflineNotice(),
          if (isOffline) const SizedBox(height: 12),
          // Summary
          Row(children: [
            _ReportCard('Tổng hóa đơn', '$totalCount HĐ', AppColors.info),
            const SizedBox(width: 12),
            _ReportCard('Tổng doanh thu', _fmtCurrency(grandTotal), AppColors.success),
            const SizedBox(width: 12),
            _ReportCard(
                'TB hàng ngày',
                _fmtCurrency(rows.isNotEmpty ? grandTotal / rows.length : 0),
                AppColors.accent),
          ]),
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
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    color: AppColors.background,
                    child: Row(children: [
                      _TH('Ngày', flex: 2),
                      _TH('Số HĐ', flex: 1),
                      _TH('Tiền giờ', flex: 2),
                      _TH('Dịch vụ', flex: 2),
                      _TH('Tổng', flex: 2),
                    ]),
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
                              horizontal: 12, vertical: 12),
                          child: Row(children: [
                            Expanded(
                                flex: 2,
                                child: Text(r.date,
                                    style: AppTextStyles.bodyMedium)),
                            Expanded(
                                flex: 1,
                                child: Text('${r.count} HĐ',
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(_fmtCurrency(r.play),
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(_fmtCurrency(r.service),
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(r.total),
                                    style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary))),
                          ]),
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

// ─── Tab 2: Member Report ─────────────────────────────────────────────────────

class _MemberReportTab extends StatelessWidget {
  final List<_MemberRow> rows;
  const _MemberReportTab({required this.rows});

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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(children: [
            _ReportCard('Tổng thành viên',
                '${rows.length} người', AppColors.info),
            const SizedBox(width: 12),
            _ReportCard('Tổng chi tiêu',
                _fmtCurrency(rows.fold(0.0, (s, m) => s + m.spend)),
                AppColors.success),
          ]),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = rows[i];
                  final tierColor = switch (m.tier) {
                    'Diamond' => AppColors.transfer,
                    'Gold' => AppColors.accent,
                    _ => AppColors.textSecondary,
                  };
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                          m.name.trim().isNotEmpty
                              ? m.name.trim()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(m.name, style: AppTextStyles.titleMedium),
                    subtitle: Text(m.phone, style: AppTextStyles.labelSmall),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m.tier,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tierColor)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${m.points} điểm',
                                style: AppTextStyles.labelLarge),
                            Text(_fmtCurrency(m.spend),
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.primary)),
                          ]),
                    ]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Product Report ────────────────────────────────────────────────────

class _ProductReportTab extends StatelessWidget {
  final List<_ProductRow> products;
  const _ProductReportTab({required this.products});

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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.background,
              child: Row(children: [
                _TH('Sản phẩm', flex: 3),
                _TH('Danh mục', flex: 2),
                _TH('Đã bán', flex: 1),
                _TH('Tồn kho', flex: 1),
                _TH('Doanh thu', flex: 2),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = products[i];
                  final isOutOfStock = p.stock == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(children: [
                      Expanded(
                          flex: 3,
                          child: Text(p.name,
                              style: AppTextStyles.bodyMedium)),
                      Expanded(
                          flex: 2,
                          child: Text(p.category,
                              style: AppTextStyles.bodySmall)),
                      Expanded(
                          flex: 1,
                          child: Text('${p.sold}',
                              style: AppTextStyles.bodySmall)),
                      Expanded(
                          flex: 1,
                          child: Text('${p.stock}',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: isOutOfStock
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontWeight: isOutOfStock
                                      ? FontWeight.w700
                                      : FontWeight.w400))),
                      Expanded(
                          flex: 2,
                          child: Text(_fmtCurrency(p.revenue),
                              style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary))),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Offline Notice ───────────────────────────────────────────────────────────

class _OfflineNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang hiển thị dữ liệu cục bộ (offline). Kết nối mạng để lấy dữ liệu mới nhất.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
            ),
          ),
        ]),
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
              Text(value,
                  style: AppTextStyles.headlineMedium.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
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
        child: Text(text,
            style: AppTextStyles.labelSmall
                .copyWith(fontWeight: FontWeight.w700)),
      );
}
