import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTimeRange? _dateRange;

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
                    '${_fmtDate(_dateRange!.start)} – ${_fmtDate(_dateRange!.end)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang xuất báo cáo CSV...'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                        ));
                  },
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Xuất CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
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
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _InvoiceReportTab(dateRange: _dateRange!),
              _MemberReportTab(),
              _ProductReportTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Invoice Report ────────────────────────────────────────────────────

class _InvoiceReportTab extends StatelessWidget {
  final DateTimeRange dateRange;
  const _InvoiceReportTab({required this.dateRange});

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
    const mockData = [
      {'date': '22/05/2026', 'count': 12, 'play': 1200000.0, 'service': 450000.0, 'total': 1650000.0},
      {'date': '21/05/2026', 'count': 9, 'play': 850000.0, 'service': 320000.0, 'total': 1170000.0},
      {'date': '20/05/2026', 'count': 15, 'play': 1500000.0, 'service': 600000.0, 'total': 2100000.0},
      {'date': '19/05/2026', 'count': 7, 'play': 620000.0, 'service': 210000.0, 'total': 830000.0},
      {'date': '18/05/2026', 'count': 11, 'play': 980000.0, 'service': 390000.0, 'total': 1370000.0},
    ];

    final grandTotal =
        mockData.fold(0.0, (s, r) => s + (r['total'] as double));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Summary
          Row(children: [
            _ReportCard('Tổng hóa đơn',
                '${mockData.fold(0, (s, r) => s + (r['count'] as int))} HĐ',
                AppColors.info),
            const SizedBox(width: 12),
            _ReportCard(
                'Tổng doanh thu', _fmtCurrency(grandTotal), AppColors.success),
            const SizedBox(width: 12),
            _ReportCard(
                'TB hàng ngày',
                _fmtCurrency(grandTotal / mockData.length),
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
                      itemCount: mockData.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = mockData[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(children: [
                            Expanded(
                                flex: 2,
                                child: Text(r['date'] as String,
                                    style: AppTextStyles.bodyMedium)),
                            Expanded(
                                flex: 1,
                                child: Text('${r['count']} HĐ',
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(r['play'] as double),
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(r['service'] as double),
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(r['total'] as double),
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
  final _mockMembers = const [
    {'name': 'Nguyễn Văn Hùng', 'phone': '0901234567', 'tier': 'Gold', 'points': 1250, 'spend': 12500000.0},
    {'name': 'Trần Thị Mai', 'phone': '0987654321', 'tier': 'Silver', 'points': 480, 'spend': 4800000.0},
    {'name': 'Lê Văn Dũng', 'phone': '0912345678', 'tier': 'Diamond', 'points': 3200, 'spend': 32000000.0},
    {'name': 'Phạm Minh Tuấn', 'phone': '0923456789', 'tier': 'Silver', 'points': 230, 'spend': 2300000.0},
  ];

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
                '${_mockMembers.length} người', AppColors.info),
            const SizedBox(width: 12),
            _ReportCard('Tổng chi tiêu',
                _fmtCurrency(
                    _mockMembers.fold(0.0, (s, m) => s + (m['spend'] as double))),
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
                itemCount: _mockMembers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = _mockMembers[i];
                  final tierColor = switch (m['tier'] as String) {
                    'Diamond' => AppColors.transfer,
                    'Gold' => AppColors.accent,
                    _ => AppColors.textSecondary,
                  };
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                          (m['name'] as String).trim().isNotEmpty
                              ? (m['name'] as String).trim()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(m['name'] as String,
                        style: AppTextStyles.titleMedium),
                    subtitle: Text(m['phone'] as String,
                        style: AppTextStyles.labelSmall),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m['tier'] as String,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tierColor)),
                      ),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${m['points']} điểm',
                            style: AppTextStyles.labelLarge),
                        Text(_fmtCurrency(m['spend'] as double),
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
  final _products = const [
    {'name': 'Sting Dâu Đỏ', 'category': 'Đồ uống', 'sold': 148, 'stock': 52, 'revenue': 2220000.0},
    {'name': 'Bia Tiger', 'category': 'Đồ uống', 'sold': 95, 'stock': 35, 'revenue': 2850000.0},
    {'name': 'Mì Xào Bò', 'category': 'Đồ ăn', 'sold': 62, 'stock': 0, 'revenue': 2170000.0},
    {'name': 'Red Bull', 'category': 'Đồ uống', 'sold': 58, 'stock': 24, 'revenue': 1450000.0},
    {'name': 'Thuốc Lá Marlboro', 'category': 'Thuốc lá', 'sold': 41, 'stock': 12, 'revenue': 1148000.0},
  ];

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                itemCount: _products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _products[i];
                  final isOutOfStock = (p['stock'] as int) == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(children: [
                      Expanded(
                          flex: 3,
                          child: Text(p['name'] as String,
                              style: AppTextStyles.bodyMedium)),
                      Expanded(
                          flex: 2,
                          child: Text(p['category'] as String,
                              style: AppTextStyles.bodySmall)),
                      Expanded(
                          flex: 1,
                          child: Text('${p['sold']}',
                              style: AppTextStyles.bodySmall)),
                      Expanded(
                          flex: 1,
                          child: Text('${p['stock']}',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: isOutOfStock
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontWeight: isOutOfStock
                                      ? FontWeight.w700
                                      : FontWeight.w400))),
                      Expanded(
                          flex: 2,
                          child: Text(
                              _fmtCurrency(p['revenue'] as double),
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
