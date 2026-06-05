import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'tables_provider.dart';
import '../../core/utils/string_utils.dart';
import '../billing/member_lookup.dart';
import '../billing/discount_panel.dart';
import '../billing/invoice_dialog.dart';
import '../billing/table_merge_dialog.dart';
import '../sync/sync_provider.dart';
import '../../core/providers/providers.dart';
import '../auth/auth_provider.dart';
import 'package:flutter/services.dart';


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

  // Quick product search suggest variables
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredSuggestions = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchFocusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final localDb = ref.read(localDbServiceProvider);
      final cachedCats = await localDb.getCachedProductCategories();
      final cached = await localDb.getCachedProducts();
      
      final catMap = {
        for (final c in cachedCats)
          c['id']?.toString() ?? '': c['category_name'] as String? ?? 'Khác'
      };

      final mapped = cached.map((p) {
        final catIdStr = p['category_id']?.toString();
        final catName = catMap[catIdStr] ?? p['category_name'] as String? ?? p['category'] as String? ?? 'Khác';
        return {
          'id': p['id']?.toString() ?? p['product_id']?.toString() ?? '',
          'name': p['product_name'] as String? ?? p['name'] as String? ?? '—',
          'price': double.tryParse(p['selling_price']?.toString() ?? p['price']?.toString() ?? '') ?? 0.0,
          'category': catName,
          'barcode': p['barcode']?.toString() ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allProducts = mapped;
        });
      }
    } catch (e) {
      debugPrint('Error loading products in TablesScreen: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _highlightedIndex = 0;
      });
      return;
    }

    final normalizedQuery = removeDiacritics(query).toLowerCase();
    final matches = _allProducts.where((p) {
      final name = p['name'] as String? ?? '';
      final barcode = p['barcode'] as String? ?? '';
      
      final normalizedName = removeDiacritics(name).toLowerCase();
      final normalizedBarcode = removeDiacritics(barcode).toLowerCase();

      return normalizedName.contains(normalizedQuery) ||
             normalizedBarcode.contains(normalizedQuery);
    }).toList();

    setState(() {
      _filteredSuggestions = matches.take(8).toList();
      _highlightedIndex = 0;
    });
  }

  void _addHighlightedProduct() {
    if (_filteredSuggestions.isEmpty) return;
    final product = _filteredSuggestions[_highlightedIndex];
    
    final tablesState = ref.read(tablesProvider);
    final isTargetActive = tablesState.selectedTable != null && tablesState.selectedTable!.status == 'active';
    final isTargetUnpaid = tablesState.selectedUnpaidInvoiceId != null;
    final targetId = isTargetActive ? tablesState.selectedTable!.id : (isTargetUnpaid ? tablesState.selectedUnpaidInvoiceId : null);

    if (targetId != null) {
      ref.read(tablesProvider.notifier).addProductToTable(
        targetId,
        {
          'product_id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'qty': 1,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã thêm ${product['name']} vào hóa đơn'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        width: 280,
      ));
    }

    setState(() {
      _filteredSuggestions = [];
      _highlightedIndex = 0;
      _searchCtrl.clear();
    });
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

    final selectedTable = tablesState.selectedTable;
    final selectedUnpaid = tablesState.selectedUnpaidInvoiceId != null
        ? tablesState.unpaidInvoices.firstWhere(
            (inv) => inv.id == tablesState.selectedUnpaidInvoiceId,
            orElse: () => null as dynamic,
          )
        : null;

    final isTargetActive = selectedTable != null && selectedTable.status == 'active';
    final isTargetUnpaid = selectedUnpaid != null;
    final targetId = isTargetActive ? selectedTable.id : (isTargetUnpaid ? selectedUnpaid.id : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── COLUMN 1: Sơ đồ bàn & Hóa đơn chờ (Left, 2/3 Width) ──
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Sơ đồ bàn (Vùng trên, 2/3 chiều cao)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── HEADER ──
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                          // Simulator Toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 12),

                      // ── FILTER CHIPS ──
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
                      const SizedBox(height: 12),

                      // ── TABLE GRID ──
                      Expanded(
                        child: tablesState.isLoading && tablesState.tables.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Đang tải danh sách bàn từ database...',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : tablesState.error != null && tablesState.tables.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Lỗi tải dữ liệu: ${tablesState.error}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => ref.read(tablesProvider.notifier).loadTables(),
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Thử lại'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : filteredTables.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.table_bar_outlined,
                                              size: 64,
                                              color: AppColors.textMuted.withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _filterStatus == 'all'
                                                  ? 'Không có dữ liệu bàn chơi. Vui lòng đồng bộ.'
                                                  : 'Không tìm thấy bàn nào với trạng thái này.',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if (_filterStatus == 'all') ...[
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () => ref.read(syncStateProvider.notifier).syncNow(),
                                                icon: const Icon(Icons.sync),
                                                label: const Text('Đồng bộ dữ liệu ngay'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      )
                                    : LayoutBuilder(
                                        builder: (context, constraints) {
                                          final W = constraints.maxWidth;
                                          final H = constraints.maxHeight;
                                          final itemCount = filteredTables.length;
                                          if (itemCount == 0) return const SizedBox.shrink();

                                          int columns = 2;
                                          if (W > 750) {
                                            columns = 4;
                                          } else if (W > 500) {
                                            columns = 3;
                                          }
                                          
                                          final rows = (itemCount / columns).ceil();
                                          
                                          const double spacing = 12.0;
                                          final w = (W - (columns - 1) * spacing) / columns;
                                          final h = (H - (rows - 1) * spacing) / rows;
                                          
                                          double aspectRatio = w / h;
                                          if (aspectRatio <= 0 || aspectRatio.isInfinite || aspectRatio.isNaN) {
                                            aspectRatio = 0.85;
                                          }

                                          return GridView.builder(
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: itemCount,
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: columns,
                                              crossAxisSpacing: spacing,
                                              mainAxisSpacing: spacing,
                                              childAspectRatio: aspectRatio,
                                            ),
                                            itemBuilder: (context, index) {
                                              final table = filteredTables[index];
                                              final typeModel = tablesState.tableTypes.firstWhere(
                                                (t) => t.id == table.tableTypeId,
                                                orElse: () => TableTypeModel(
                                                  id: table.tableTypeId,
                                                  typeName: switch (table.tableTypeId) {
                                                    1 => 'Pool (Bàn lỗ)',
                                                    2 => 'Carom (Băng)',
                                                    3 => 'Snooker',
                                                    _ => 'Bàn Bida',
                                                  },
                                                ),
                                              );
                                              final typeLabel = typeModel.typeName;
                                              final hourlyRate = tablesState.getTableHourlyRate(table);

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
                                                typeLabel: typeLabel,
                                                hourlyRate: hourlyRate,
                                              );
                                            },
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              // Hóa đơn chờ (Vùng dưới, 1/3 chiều cao)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: AppColors.background,
                  child: _buildUnpaidInvoicesSection(context, tablesState),
                ),
              ),
            ],
          ),
        ),

        // ── COLUMN 2: Chi tiết hóa đơn (Right, 1/3 Width) ──
        Expanded(
          flex: 1,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: targetId != null
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          // Quick product search suggest bar
                          _buildQuickSearchField(targetId),
                          const Divider(height: 1),
                          // Invoice detailed info
                          Expanded(
                            child: isTargetActive
                                ? _InvoicePanel(
                                    table: selectedTable!,
                                    tablesState: tablesState,
                                  )
                                : _InvoicePanelForUnpaid(
                                    invoice: selectedUnpaid!,
                                    tablesState: tablesState,
                                  ),
                          ),
                        ],
                      ),
                      
                      // Floating suggestions dropdown overlay
                      if (_filteredSuggestions.isNotEmpty)
                        Positioned(
                          top: 48, // Floating right below search field
                          left: 16,
                          right: 16,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _filteredSuggestions.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final product = _filteredSuggestions[index];
                                  final isHighlighted = index == _highlightedIndex;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _highlightedIndex = index;
                                      });
                                      _addHighlightedProduct();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      color: isHighlighted
                                          ? AppColors.primarySurface
                                          : Colors.white,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.restaurant_menu_outlined,
                                            size: 16,
                                            color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  product['name'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14,
                                                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                                                    color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
                                                  ),
                                                ),
                                                if (product['barcode'] != null && (product['barcode'] as String).isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Mã: ${product['barcode']}',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 11,
                                                      color: isHighlighted ? AppColors.primary.withOpacity(0.8) : AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _fmtCurrency(product['price'] as double),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : const _NoActiveTablePlaceholder(message: 'Vui lòng chọn bàn hoặc hóa đơn chờ để thực hiện dịch vụ'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTogglePower(TableModel table) async {
    final notifier = ref.read(tablesProvider.notifier);

    if (table.status == 'idle') {
      // Xác nhận trước khi bật bàn
      final confirmActivate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.power_settings_new_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Bật bàn chơi'),
            ],
          ),
          content: Text('Bạn có chắc chắn muốn bật bàn ${table.tableName} và bắt đầu tính giờ không?'),
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
                  'Huỷ',
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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
          ));
        }
      }
    }
  }

  Widget _buildQuickSearchField(String targetId) {
    return KeyboardListener(
      focusNode: FocusNode(canRequestFocus: false),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_filteredSuggestions.isNotEmpty) {
              setState(() {
                _highlightedIndex = (_highlightedIndex + 1) % _filteredSuggestions.length;
              });
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (_filteredSuggestions.isNotEmpty) {
              setState(() {
                _highlightedIndex = (_highlightedIndex - 1 + _filteredSuggestions.length) % _filteredSuggestions.length;
              });
            }
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _filteredSuggestions = [];
              _highlightedIndex = 0;
              _searchCtrl.clear();
            });
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          focusNode: _searchFocusNode,
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _addHighlightedProduct(),
          decoration: InputDecoration(
            hintText: 'Tìm & thêm dịch vụ nhanh...',
            hintStyle: AppTextStyles.bodySmall,
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnpaidInvoicesSection(BuildContext context, TablesState state) {
    final unpaid = state.unpaidInvoices;
    final selectedUnpaidId = state.selectedUnpaidInvoiceId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hourglass_bottom_outlined, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'DANH SÁCH HÓA ĐƠN CHỜ (${unpaid.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('BÀN', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('THỜI GIAN', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('DỊCH VỤ', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Text('TỔNG TIỀN', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('THAO TÁC', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // Table Body
        Expanded(
          child: unpaid.isEmpty
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Không có hóa đơn nào đang chờ thanh toán',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: unpaid.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final inv = unpaid[idx];
                      final isSelected = inv.id == selectedUnpaidId;
                      
                      double prodTotal = inv.products.fold(0.0,
                          (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));
                      final totalAmt = inv.playAmount + prodTotal;
                      
                      return InkWell(
                        onTap: () => ref.read(tablesProvider.notifier).selectUnpaidInvoice(inv.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          color: isSelected 
                              ? AppColors.accent.withOpacity(0.08) 
                              : (idx % 2 == 1 ? AppColors.background.withOpacity(0.4) : Colors.white),
                          child: Row(
                            children: [
                              // Bàn
                              Expanded(
                                flex: 2,
                                child: Text(
                                  inv.tableName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              // Thời gian
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${inv.playMinutes} phút',
                                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Dịch vụ
                              Expanded(
                                flex: 2,
                                child: Text(
                                  inv.products.isNotEmpty
                                      ? '${inv.products.fold(0, (sum, p) => sum + (p['qty'] as int))} món'
                                      : '0 món',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              // Tổng tiền
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _fmtCurrency(totalAmt),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              // Thao tác
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _TableCompactActionButton(
                                      icon: Icons.merge_type,
                                      tooltip: 'Gộp hóa đơn',
                                      color: AppColors.primary,
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (_) => TableMergeDialog(sourceInvoiceId: inv.id)),
                                    ),
                                    const SizedBox(width: 6),
                                    _TableCompactActionButton(
                                      icon: Icons.swap_horiz,
                                      tooltip: 'Chuyển bàn',
                                      color: AppColors.info,
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (_) => TableTransferDialog(sourceInvoiceId: inv.id)),
                                    ),
                                    const SizedBox(width: 6),
                                    _TableCompactActionButton(
                                      icon: Icons.delete_outline,
                                      tooltip: 'Huỷ hóa đơn',
                                      color: AppColors.error,
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final reason = await showDialog<String>(
                                          context: context,
                                          builder: (ctx) => _CancelInvoiceDialog(tableName: inv.tableName),
                                        );
                                        if (reason != null && reason.trim().isNotEmpty) {
                                          ref.read(tablesProvider.notifier).cancelUnpaidInvoice(inv.id, reason.trim());
                                          messenger.showSnackBar(SnackBar(
                                            content: Text('Đã huỷ hóa đơn bàn "${inv.tableName}". Đang đồng bộ...'),
                                            backgroundColor: AppColors.error,
                                            behavior: SnackBarBehavior.floating,
                                            width: 380,
                                            duration: const Duration(seconds: 3),
                                          ));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
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
  final String typeLabel;
  final double hourlyRate;

  const _TableCard({
    required this.table,
    required this.isSelected,
    required this.playDuration,
    required this.playCost,
    required this.onSelect,
    required this.onTogglePower,
    required this.onMaintenance,
    required this.typeLabel,
    required this.hourlyRate,
  });

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

    final costStr = _fmtCurrency(playCost);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final cardH = cardConstraints.maxHeight;
            final isCompact = cardH < 170;
            final padding = isCompact ? 8.0 : 12.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Status Dot ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              table.tableName,
                              style: isCompact
                                  ? AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)
                                  : AppTextStyles.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                          ],
                        ),
                      ),
                      _PulsingDot(color: statusDotColor, isActive: isActive),
                    ],
                  ),
                  
                  if (!isCompact) ...[
                    const SizedBox(height: 4),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // ── Power Icon ──
                  if (!isMaintenance)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onTogglePower,
                        child: Container(
                          width: isCompact ? 28 : 34,
                          height: isCompact ? 28 : 34,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.error.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.power_settings_new_rounded,
                            size: isCompact ? 16 : 20,
                            color: isActive ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
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

class _InvoicePanel extends ConsumerWidget {
  final TableModel table;
  final TablesState tablesState;
  const _InvoicePanel({required this.table, required this.tablesState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = tablesState.tableOrders[table.id] ?? [];
    final startTime = tablesState.tableStartTimes[table.id] ?? DateTime.now();
    final rate = tablesState.getTableHourlyRate(table);
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
                    child: Text(table.tableName, style: AppTextStyles.headlineSmall),
                  ),
                  _ActionButton(
                    icon: Icons.merge_type,
                    label: 'Gộp',
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => TableMergeDialog(sourceTableId: table.id)),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Chuyển',
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => TableTransferDialog(sourceTableId: table.id)),
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
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
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
                            '${member['full_name']} (${member['tier']} -${member['discount']}% )',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      Icon(Icons.restaurant_menu_outlined, size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Chưa có dịch vụ', style: AppTextStyles.bodySmall),
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
                          .removeProductFromTable(table.id, p['product_id'] as String),
                      onAdd: () => ref
                          .read(tablesProvider.notifier)
                          .updateProductQty(table.id, p['product_id'] as String, 1),
                      onSubtract: () => ref
                          .read(tablesProvider.notifier)
                          .updateProductQty(table.id, p['product_id'] as String, -1),
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
              _SummaryRow('Dịch vụ', _fmtCurrency(productTotal)),
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
              // Stop Timer and Payment buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Trigger stop/freeze table action
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
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                              child: const Text('Xác nhận tắt bàn'),
                            ),
                          ],
                        ),
                      );

                      if (forceDeactivate == true) {
                        final ok = await notifier.deactivateTableAndFreezeInvoice(table.id);
                        if (ok) {
                          messenger.showSnackBar(const SnackBar(
                            content: Text('Đã tắt bàn thành công. Hóa đơn đã được đưa vào danh sách chờ thanh toán.'),
                            backgroundColor: AppColors.success,
                          ));
                        }
                      }
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 14),
                    label: const Text('Tắt bàn', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
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
                        const SizedBox(width: 4),
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
                        const SizedBox(width: 4),
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
        totalAmount: finalPlayAmount + finalProductTotal,
        paymentMethod: method,
        member: member,
        onConfirm: (paymentMethod) async {
          final serverOrderId = ref.read(tablesProvider).tableServerOrderIds[table.id];
          final orderId = table.currentOrderId ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';
          final currentUser = ref.read(currentUserProvider);
          final currentUserId = currentUser?.id ?? 'system';

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
            createdBy: currentUserId,
            closedBy: currentUserId,
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
              addedBy: currentUserId,
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

          try {
            await localDb.saveOrderLocally(orderId, payload);
            await syncService.syncNow();
          } catch (e) {
            print('Lỗi lưu local/đồng bộ hóa đơn trước checkout: $e');
          }

          await ref.read(tablesProvider.notifier).deactivateTable(table.id);
        },
      ),
    );
  }
}

class _InvoicePanelForUnpaid extends ConsumerWidget {
  final UnpaidInvoice invoice;
  final TablesState tablesState;
  const _InvoicePanelForUnpaid({required this.invoice, required this.tablesState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = invoice.products;
    final startTime = invoice.startTime;
    final endTime = invoice.endTime;
    final rate = invoice.hourlyRate;
    final playAmount = invoice.playAmount;
    final productTotal = products.fold(0.0,
        (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

    final member = invoice.member;
    final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
    final manualDiscountPercent = invoice.manualDiscountPercent;
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
                    child: Text(
                      '${invoice.tableName} (Chờ)',
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.accent),
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.merge_type,
                    label: 'Gộp',
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => TableMergeDialog(sourceInvoiceId: invoice.id)),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Chuyển',
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => TableTransferDialog(sourceInvoiceId: invoice.id)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Timer display (Static / Frozen)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_off_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      '${invoice.playMinutes} phút (Đã dừng)',
                      style: AppTextStyles.mono.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      _fmtCurrency(playAmount),
                      style: AppTextStyles.currencySmall.copyWith(color: AppColors.accent),
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
                            '${member['full_name']} (${member['tier']} -${member['discount']}% )',
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
                          onTap: () => ref.read(tablesProvider.notifier).removeMember(invoice.id),
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
                          onTap: () => ref.read(tablesProvider.notifier).removeDiscount(invoice.id),
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
                      builder: (_) => MemberLookupDialog(tableId: invoice.id)),
                  icon: const Icon(Icons.person_search, size: 16),
                  label: const Text('Thành viên'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => DiscountPanel(tableId: invoice.id)),
                  icon: const Icon(Icons.local_offer_outlined, size: 16),
                  label: const Text('Khuyến mãi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      Icon(Icons.restaurant_menu_outlined, size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Chưa có dịch vụ', style: AppTextStyles.bodySmall),
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
                          .removeProductFromTable(invoice.id, p['product_id'] as String),
                      onAdd: () => ref
                          .read(tablesProvider.notifier)
                          .updateProductQty(invoice.id, p['product_id'] as String, 1),
                      onSubtract: () => ref
                          .read(tablesProvider.notifier)
                          .updateProductQty(invoice.id, p['product_id'] as String, -1),
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
              _SummaryRow('Dịch vụ', _fmtCurrency(productTotal)),
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
                    onTap: () => _checkoutUnpaid(
                      context,
                      ref,
                      'cash',
                      playAmount,
                      productTotal,
                      discountPercent,
                      discountAmount,
                      netTotal,
                      startTime,
                      endTime,
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
                    onTap: () => _checkoutUnpaid(
                      context,
                      ref,
                      'card',
                      playAmount,
                      productTotal,
                      discountPercent,
                      discountAmount,
                      netTotal,
                      startTime,
                      endTime,
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
                    onTap: () => _checkoutUnpaid(
                      context,
                      ref,
                      'transfer',
                      playAmount,
                      productTotal,
                      discountPercent,
                      discountAmount,
                      netTotal,
                      startTime,
                      endTime,
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

  Future<void> _checkoutUnpaid(
    BuildContext context,
    WidgetRef ref,
    String method,
    double playAmount,
    double productTotal,
    double discountPercent,
    double discountAmount,
    double netTotal,
    DateTime startTime,
    DateTime endTime,
    List<Map<String, dynamic>> products,
    double rate,
    Map<String, dynamic>? member,
  ) async {
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
        discountPercent: discountPercent,
        discountAmount: finalDiscountAmount,
        netTotal: finalNetTotal,
        totalAmount: finalPlayAmount + finalProductTotal,
        paymentMethod: method,
        member: member,
        onConfirm: (paymentMethod) async {
          final orderId = invoice.id;
          final currentUser = ref.read(currentUserProvider);
          final currentUserId = currentUser?.id ?? 'system';

          final orderModel = OrderModel(
            id: orderId,
            tableId: invoice.tableId,
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
            createdBy: currentUserId,
            closedBy: currentUserId,
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
              addedBy: currentUserId,
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

          try {
            await localDb.saveOrderLocally(orderId, payload);
            await syncService.syncNow();
          } catch (e) {
            print('Lỗi lưu local/đồng bộ hóa đơn trước checkout: $e');
          }

          ref.read(tablesProvider.notifier).completeUnpaidInvoicePayment(invoice.id);
        },
      ),
    );
  }
}

  String _fmtDuration(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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

class _NoActiveTablePlaceholder extends StatelessWidget {
  final String message;
  const _NoActiveTablePlaceholder({
    super.key,
    this.message = 'Chưa chọn bàn hoặc hóa đơn chờ',
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_bar_outlined, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textMuted, fontSize: 15),
              ),
            ],
          ),
        ),
      );
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
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ]),
      );
}

class _ProductLineItem extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  const _ProductLineItem({
    required this.name,
    required this.qty,
    required this.price,
    required this.onRemove,
    required this.onAdd,
    required this.onSubtract,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodySmall),
                  Text(_fmtCurrency(price), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: onSubtract,
                  child: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.textSecondary),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                InkWell(
                  onTap: onAdd,
                  child: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(_fmtCurrency(price * qty), style: AppTextStyles.labelLarge),
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
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
  const _PayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _TableCompactActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _TableCompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─── Cancel Invoice Dialog ────────────────────────────────────────────────────

class _CancelInvoiceDialog extends StatefulWidget {
  final String tableName;
  const _CancelInvoiceDialog({required this.tableName});

  @override
  State<_CancelInvoiceDialog> createState() => _CancelInvoiceDialogState();
}

class _CancelInvoiceDialogState extends State<_CancelInvoiceDialog> {
  final _reasonCtrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl.addListener(() {
      final hasText = _reasonCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
          SizedBox(width: 8),
          Text(
            'Huỷ hóa đơn',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary),
                children: [
                  const TextSpan(text: 'Bạn đang huỷ hóa đơn của bàn '),
                  TextSpan(
                    text: '"${widget.tableName}"',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                  const TextSpan(text: '.\nThao tác này '),
                  const TextSpan(
                    text: 'không thể hoàn tác',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lý do huỷ *',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonCtrl,
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Nhập lý do huỷ hóa đơn...',
                hintStyle: AppTextStyles.bodySmall,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
            if (!_hasText)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠ Vui lòng nhập lý do trước khi xác nhận.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Không huỷ', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: _hasText ? () => Navigator.of(context).pop(_reasonCtrl.text) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.errorLight,
          ),
          icon: const Icon(Icons.delete_forever_outlined, size: 16),
          label: const Text('Xác nhận huỷ', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
