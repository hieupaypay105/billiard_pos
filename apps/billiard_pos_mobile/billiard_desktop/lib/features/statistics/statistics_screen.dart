import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

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
              Text('Thống kê', style: AppTextStyles.headlineLarge),
              Text('Tổng hợp dữ liệu hoạt động theo ca và ngày.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.titleMedium,
                tabs: const [
                  Tab(text: 'Hóa đơn hôm nay'),
                  Tab(text: 'Ca thu ngân'),
                  Tab(text: 'Sản phẩm bán chạy'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _InvoiceTodayTab(),
              _ShiftSummaryTab(),
              _TopProductsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Today's Invoices ──────────────────────────────────────────────────

class _InvoiceTodayTab extends StatelessWidget {
  final _mockInvoices = const [
    {'table': 'Bàn 01 (Pool)', 'start': '08:30', 'end': '10:15', 'play': 145000.0, 'service': 55000.0, 'total': 200000.0, 'method': 'cash'},
    {'table': 'Bàn 03 (Pool)', 'start': '09:00', 'end': '11:30', 'play': 200000.0, 'service': 80000.0, 'total': 280000.0, 'method': 'transfer'},
    {'table': 'Bàn 04 (Carom)', 'start': '10:00', 'end': '12:00', 'play': 180000.0, 'service': 30000.0, 'total': 210000.0, 'method': 'card'},
    {'table': 'Bàn 06 (Snooker)', 'start': '11:00', 'end': '13:30', 'play': 300000.0, 'service': 120000.0, 'total': 420000.0, 'method': 'cash'},
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
    final totalRevenue =
        _mockInvoices.fold(0.0, (s, i) => s + (i['total'] as double));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Summary row
          Row(children: [
            _StatCard('Tổng hóa đơn', '${_mockInvoices.length}',
                Icons.receipt_long, AppColors.info),
            const SizedBox(width: 12),
            _StatCard('Doanh thu hôm nay', _fmtCurrency(totalRevenue),
                Icons.attach_money, AppColors.success),
            const SizedBox(width: 12),
            _StatCard('Trung bình/HĐ',
                _fmtCurrency(totalRevenue / _mockInvoices.length),
                Icons.trending_up, AppColors.accent),
          ]),
          const SizedBox(height: 20),
          // Invoice table
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
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12)),
                    ),
                    child: Row(children: [
                      _Col('Bàn', flex: 3),
                      _Col('Giờ vào', flex: 2),
                      _Col('Giờ ra', flex: 2),
                      _Col('Tiền giờ', flex: 2),
                      _Col('Dịch vụ', flex: 2),
                      _Col('Tổng', flex: 2),
                      _Col('TT', flex: 2),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _mockInvoices.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final inv = _mockInvoices[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(children: [
                            Expanded(
                                flex: 3,
                                child: Text(
                                    inv['table'] as String,
                                    style: AppTextStyles.bodyMedium)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    inv['start'] as String,
                                    style: AppTextStyles.mono
                                        .copyWith(fontSize: 13))),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    inv['end'] as String,
                                    style: AppTextStyles.mono
                                        .copyWith(fontSize: 13))),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(inv['play'] as double),
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(inv['service'] as double),
                                    style: AppTextStyles.bodySmall)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    _fmtCurrency(inv['total'] as double),
                                    style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary))),
                            Expanded(
                                flex: 2,
                                child: _MethodChip(
                                    inv['method'] as String)),
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

// ─── Tab 2: Shift Summary ─────────────────────────────────────────────────────

class _ShiftSummaryTab extends StatefulWidget {
  @override
  State<_ShiftSummaryTab> createState() => _ShiftSummaryTabState();
}

class _ShiftSummaryTabState extends State<_ShiftSummaryTab> {
  bool _shiftOpen = false;
  final _cashCtrl = TextEditingController(text: '500000');

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
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Shift control
          SizedBox(
            width: 320,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _shiftOpen
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _shiftOpen ? 'Ca đang mở' : 'Chưa mở ca',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: _shiftOpen
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Text('Tiền đầu ca (đ):', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_shiftOpen,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.money, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _shiftOpen = !_shiftOpen),
                        icon: Icon(_shiftOpen
                            ? Icons.lock_clock
                            : Icons.play_circle_outlined),
                        label: Text(
                            _shiftOpen ? 'Đóng ca & Đối soát' : 'Mở ca mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _shiftOpen
                              ? AppColors.error
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right: Shift summary
          if (_shiftOpen)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng kết ca hiện tại',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 16),
                    Row(children: [
                      _StatCard('Tiền mặt', _fmtCurrency(780000),
                          Icons.money, AppColors.cash),
                      const SizedBox(width: 12),
                      _StatCard('Chuyển khoản', _fmtCurrency(280000),
                          Icons.qr_code, AppColors.transfer),
                      const SizedBox(width: 12),
                      _StatCard('Thẻ', _fmtCurrency(210000),
                          Icons.credit_card, AppColors.card),
                      const SizedBox(width: 12),
                      _StatCard('Tổng doanh thu', _fmtCurrency(1270000),
                          Icons.bar_chart, AppColors.primary),
                    ]),
                    const SizedBox(height: 20),
                    Text('Tiền mặt thực tế:',
                        style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Nhập số tiền đếm được...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        prefixIcon:
                            const Icon(Icons.calculate_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_open,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('Mở ca để bắt đầu làm việc',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Top Products ──────────────────────────────────────────────────────

class _TopProductsTab extends StatelessWidget {
  final _mockData = const [
    {'name': 'Sting Dâu Đỏ', 'qty': 48, 'revenue': 720000.0},
    {'name': 'Bia Tiger', 'qty': 35, 'revenue': 1050000.0},
    {'name': 'Nước Lọc Aquafina', 'qty': 30, 'revenue': 300000.0},
    {'name': 'Mì Xào Bò', 'qty': 22, 'revenue': 770000.0},
    {'name': 'Red Bull', 'qty': 20, 'revenue': 500000.0},
    {'name': 'Thuốc Lá Marlboro', 'qty': 15, 'revenue': 420000.0},
  ];

  @override
  Widget build(BuildContext context) {
    final maxQty = _mockData.fold(0, (m, d) {
      final q = d['qty'] as int;
      return q > m ? q : m;
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar chart
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top sản phẩm theo số lượng',
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxQty.toDouble() + 5,
                        barGroups: _mockData.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['qty'] as int).toDouble(),
                                color: AppColors.primary,
                                width: 28,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final i = val.toInt();
                                if (i >= _mockData.length) {
                                  return const SizedBox();
                                }
                                final name =
                                    (_mockData[i]['name'] as String)
                                        .split(' ')
                                        .first;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(name,
                                      style: AppTextStyles.labelSmall),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // List
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Chi tiết', style: AppTextStyles.headlineSmall),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _mockData.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = _mockData[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primarySurface,
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(p['name'] as String,
                                    style: AppTextStyles.bodySmall)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${p['qty']} sp',
                                    style: AppTextStyles.labelLarge),
                              ],
                            ),
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelSmall),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.titleLarge
                          .copyWith(color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),
      );
}

class _MethodChip extends StatelessWidget {
  final String method;
  const _MethodChip(this.method);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (method) {
      'cash' => ('Tiền mặt', AppColors.cash),
      'card' => ('Thẻ', AppColors.card),
      'transfer' => ('QR/CK', AppColors.transfer),
      _ => (method, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _Col extends StatelessWidget {
  final String text;
  final int flex;
  const _Col(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: AppTextStyles.labelSmall
                .copyWith(fontWeight: FontWeight.w700)),
      );
}
