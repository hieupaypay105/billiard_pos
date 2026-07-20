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
import '../billing/add_product_panel.dart';
import '../sync/sync_provider.dart';
import '../../core/providers/providers.dart';
import '../auth/auth_provider.dart';
import 'shift_provider.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/sync_service.dart';
import 'package:flutter/services.dart';
import '../update/update_service.dart';
import '../update/update_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/providers/device_connection_provider.dart';
import 'package:iot_controller/iot_controller.dart';


class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  Timer? _ticker;
  int? _selectedTableTypeId;
  static bool _hasCheckedUpdate = false;
  bool _isNotificationDialogOpen = false;
  bool _isDeviceRequestDialogOpen = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    _checkAppUpdate();
  }

  void _checkAppUpdate() {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final updateInfo = await ref.read(updateCheckProvider.future);
        if (updateInfo.hasUpdate && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UpdateDialog(updateInfo: updateInfo),
          );
        }
      } catch (e) {
        debugPrint('[TablesScreen] Auto-update check error: $e');
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchFocusNode.dispose();
    _searchCtrl.dispose();
    _audioPlayer.dispose();
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

  void _showDeviceRequestDialog(BuildContext context, WidgetRef ref, DeviceRequest req) {
    if (_isDeviceRequestDialogOpen) return;
    _isDeviceRequestDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.wifi_tethering, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Yêu cầu kết nối thiết bị'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Có thiết bị muốn kết nối vào hệ thống cơ sở dữ liệu của bạn:'),
            const SizedBox(height: 12),
            Text('· Tên thiết bị: ${req.deviceName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('· Hệ điều hành: ${req.os}'),
            Text('· Địa chỉ IP: ${req.ip}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(deviceConnectionProvider.notifier).denyDevice(req.deviceId);
              Navigator.pop(ctx);
            },
            child: const Text('Từ chối', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(deviceConnectionProvider.notifier).approveDevice(req.deviceId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    ).then((_) {
      _isDeviceRequestDialogOpen = false;
    });
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

  Future<void> _addHighlightedProduct() async {
    if (_filteredSuggestions.isEmpty) return;
    final product = _filteredSuggestions[_highlightedIndex];
    
    final tablesState = ref.read(tablesProvider);
    final isTargetActive = tablesState.selectedTable != null && tablesState.selectedTable!.status == 'active';
    final isTargetUnpaid = tablesState.selectedUnpaidInvoiceId != null;
    final targetId = isTargetActive ? tablesState.selectedTable!.id : (isTargetUnpaid ? tablesState.selectedUnpaidInvoiceId : null);

    if (targetId != null) {
      final quantity = await showDialog<int>(
        context: context,
        builder: (ctx) => QuantityPickerDialog(
          productName: product['name'] as String,
          price: product['price'] as double,
        ),
      );
      if (quantity == null || quantity <= 0) {
        _searchFocusNode.requestFocus();
        return;
      }

      ref.read(tablesProvider.notifier).addProductToTable(
        targetId,
        {
          'product_id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'qty': quantity,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã thêm x$quantity ${product['name']} vào hóa đơn'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          width: 280,
        ));
      }
    }

    setState(() {
      _filteredSuggestions = [];
      _highlightedIndex = 0;
      _searchCtrl.clear();
    });
    if (mounted) _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TablesState>(tablesProvider, (previous, next) {
      final prevLen = previous?.mobileProductNotifications.length ?? 0;
      final nextLen = next.mobileProductNotifications.length;
      if (nextLen > prevLen) {
        _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      }

      if (nextLen > 0 && !_isNotificationDialogOpen) {
        _isNotificationDialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const MobileProductsNotificationDialog(),
        ).then((_) {
          _isNotificationDialogOpen = false;
          ref.read(tablesProvider.notifier).clearMobileProductNotifications();
        });
      }
    });

    ref.listen<DeviceConnectionState>(deviceConnectionProvider, (previous, next) {
      if (next.pendingRequests.isNotEmpty) {
        final req = next.pendingRequests.first;
        _showDeviceRequestDialog(context, ref, req);
      }
    });

    final tablesState = ref.watch(tablesProvider);
    final activeTableTypeId = _selectedTableTypeId ?? 
        (tablesState.tableTypes.isNotEmpty ? tablesState.tableTypes.first.id : null);
    final filteredTables = activeTableTypeId == null
        ? tablesState.tables
        : tablesState.tables
            .where((t) => t.tableTypeId == activeTableTypeId)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          // Global IoT Simulator Toggle
                          Row(
                            children: [
                              Icon(
                                tablesState.useSimulator ? Icons.sports_esports : Icons.router,
                                color: tablesState.useSimulator ? AppColors.success : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Giả lập IoT',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: tablesState.useSimulator ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: tablesState.useSimulator,
                                activeColor: AppColors.success,
                                onChanged: (val) {
                                  ref.read(tablesProvider.notifier).toggleSimulator(val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── TABLE TYPE TABS ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Table type chips
                            ...tablesState.tableTypes.map((type) {
                              final count = tablesState.tables
                                  .where((t) => t.tableTypeId == type.id)
                                  .length;
                              final isSelected = activeTableTypeId == type.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text('${type.typeName} ($count)'),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => _selectedTableTypeId = type.id),
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
                              );
                            }),
                          ],
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
                                              tablesState.tables.isEmpty
                                                  ? 'Không có dữ liệu bàn chơi. Vui lòng đồng bộ.'
                                                  : 'Không tìm thấy bàn nào thuộc loại này.',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if (tablesState.tables.isEmpty) ...[
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

                                              final pendingCount = tablesState.tablePendingOrders[table.id]?.length ?? 0;
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
                                                pendingOrdersCount: pendingCount,
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
            child: selectedUnpaid != null
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          _buildQuickSearchField(selectedUnpaid.id),
                          const Divider(height: 1),
                          Expanded(
                            child: _InvoicePanelForUnpaid(
                              invoice: selectedUnpaid,
                              tablesState: tablesState,
                            ),
                          ),
                        ],
                      ),
                      if (_filteredSuggestions.isNotEmpty)
                        Positioned(
                          top: 48,
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
                : selectedTable != null
                    ? (selectedTable.status == 'active'
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                children: [
                                  _buildQuickSearchField(selectedTable.id),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: _InvoicePanel(
                                      table: selectedTable,
                                      tablesState: tablesState,
                                    ),
                                  ),
                                ],
                              ),
                              if (_filteredSuggestions.isNotEmpty)
                                Positioned(
                                  top: 48,
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
                        : _IdleTablePanel(
                            table: selectedTable,
                            tablesState: tablesState,
                            onTogglePower: () => _handleTogglePower(selectedTable),
                          ))
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể bật bàn vì kết nối hoặc gửi lệnh đến Relay IoT thất bại.'),
            backgroundColor: AppColors.error,
          ),
        );
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
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không thể tắt bàn vì gửi lệnh tắt đến Relay IoT thất bại.'),
            backgroundColor: AppColors.error,
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
                        onTap: () {
                          ref.read(tablesProvider.notifier).selectUnpaidInvoice(inv.id);
                        },
                        onDoubleTap: () async {
                          ref.read(tablesProvider.notifier).selectUnpaidInvoice(inv.id);
                          
                          final currentUser = ref.read(currentUserProvider);
                          final currentUserId = currentUser?.id ?? 'system';
                          final currentShiftId = ref.read(currentShiftIdProvider) ?? 'shift-default';
                          final localDb = ref.read(localDbServiceProvider);
                          final syncService = ref.read(syncServiceProvider);
                          final tablesNotifier = ref.read(tablesProvider.notifier);

                          final products = inv.products;
                          final startTime = inv.startTime;
                          final endTime = inv.endTime;
                          final rate = inv.hourlyRate;
                          final playAmount = inv.playAmount;
                          
                          final member = inv.member;
                          final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
                          final discountPlayPercent = inv.discountPlayPercent;
                          final discountServicePercent = inv.discountServicePercent;
                          final discountBillPercent = inv.discountBillPercent;
                          
                          final playDiscountAmount = playAmount * (discountPlayPercent / 100.0);
                          final serviceDiscountAmount = prodTotal * (discountServicePercent / 100.0);
                          final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
                          final billDiscountAmount = (playAmount + prodTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
                          final discountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
                          final netTotal = playAmount + prodTotal - discountAmount;

                          await _checkoutUnpaidInvoice(
                            context: context,
                            currentUserId: currentUserId,
                            currentShiftId: currentShiftId,
                            localDb: localDb,
                            syncService: syncService,
                            tablesNotifier: tablesNotifier,
                            invoice: inv,
                            initialStatus: 'paid',
                            playAmount: playAmount,
                            productTotal: prodTotal,
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
                        },
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
  final int pendingOrdersCount;

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
    required this.pendingOrdersCount,
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
                      if (pendingOrdersCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingOrdersCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
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
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = (currentUser?.role.toLowerCase() ?? '').contains('admin') || currentUser?.role.toLowerCase() == 'manager';
    final products = tablesState.tableOrders[table.id] ?? [];
    final startTime = tablesState.tableStartTimes[table.id] ?? DateTime.now();
    final rate = tablesState.getTableHourlyRate(table);
    final duration = tablesState.playDuration(table.id);
    final playAmount = tablesState.playCost(table.id);
    double productTotal = products.fold(0.0,
        (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

    final member = tablesState.tableMembers[table.id];
    final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
    
    final discountPlayPercent = tablesState.tablePlayDiscounts[table.id] ?? 0.0;
    final discountServicePercent = tablesState.tableServiceDiscounts[table.id] ?? 0.0;
    final discountBillPercent = tablesState.tableBillDiscounts[table.id] ?? 0.0;
    
    final playDiscountAmount = playAmount * (discountPlayPercent / 100.0);
    final serviceDiscountAmount = productTotal * (discountServicePercent / 100.0);
    final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
    final billDiscountAmount = (playAmount + productTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
    final discountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
    final netTotal = (playAmount + productTotal) - discountAmount;

    return Column(
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.settings_remote,
                      label: 'IoT',
                      onTap: () => showDialog(
                          context: context,
                          builder: (_) => IotConfigDialog(
                                table: table,
                                initialConfig: tablesState.iotConfigs[table.id],
                              )),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Timer display
              if (rate > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        if (member != null || discountPlayPercent > 0 || discountServicePercent > 0 || discountBillPercent > 0)
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
                          onTap: () => ref.read(tablesProvider.notifier).removeDiscount(table.id),
                          child: const Icon(Icons.cancel, size: 16, color: AppColors.accent),
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
                          onTap: () => ref.read(tablesProvider.notifier).removeDiscount(table.id),
                          child: const Icon(Icons.cancel, size: 16, color: AppColors.accent),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
          child: (products.isEmpty && (tablesState.tablePendingOrders[table.id]?.isEmpty ?? true))
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
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (products.isNotEmpty) ...[
                      if (tablesState.tablePendingOrders[table.id]?.isNotEmpty ?? false)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            'ĐÃ DUYỆT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ...products.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _ProductLineItem(
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
                            ),
                          )),
                    ],
                    if (tablesState.tablePendingOrders[table.id]?.isNotEmpty ?? false) ...[
                      Padding(
                        padding: EdgeInsets.only(
                          top: products.isNotEmpty ? 16.0 : 4.0,
                          bottom: 8.0,
                        ),
                        child: const Text(
                          'YÊU CẦU CHỜ DUYỆT (TỪ MOBILE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...(tablesState.tablePendingOrders[table.id] ?? []).map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PendingProductLineItem(
                              name: p['name'] as String,
                              qty: p['qty'] as int,
                              price: p['price'] as double,
                              onApprove: () => ref
                                  .read(tablesProvider.notifier)
                                  .approvePendingProduct(table.id, p['product_id'] as String),
                              onDeny: () => ref
                                  .read(tablesProvider.notifier)
                                  .denyPendingProduct(table.id, p['product_id'] as String),
                            ),
                          )),
                    ],
                  ],
                ),
        ),
        const Divider(height: 1),

        // ── Total & Payment ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Summary rows
              if (rate > 0)
                _SummaryRow('Tiền giờ chơi', _fmtCurrency(playAmount)),
              _SummaryRow('Dịch vụ', _fmtCurrency(productTotal)),
              if (discountPlayPercent > 0)
                _SummaryRow(
                  'Chiết khấu giờ chơi (${discountPlayPercent.toInt()}%)',
                  '-${_fmtCurrency(playDiscountAmount)}',
                ),
              if (discountServicePercent > 0)
                _SummaryRow(
                  'Chiết khấu dịch vụ (${discountServicePercent.toInt()}%)',
                  '-${_fmtCurrency(serviceDiscountAmount)}',
                ),
              if (discountBillPercent > 0 || memberDiscountPercent > 0)
                _SummaryRow(
                  memberDiscountPercent > 0
                      ? 'Chiết khấu HĐ & TV (${(discountBillPercent + memberDiscountPercent).toInt()}%)'
                      : 'Chiết khấu hóa đơn (${discountBillPercent.toInt()}%)',
                  '-${_fmtCurrency(billDiscountAmount)}',
                ),
              const Divider(height: 12),
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
              const SizedBox(height: 10),
              // Payment buttons (Stop Timer button removed from here)
              Row(
                children: [
                  _PayButton(
                    label: 'Thanh toán',
                    icon: Icons.payment_rounded,
                    color: AppColors.primary,
                    onTap: () => _handleCheckoutTap(
                      context,
                      ref,
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
                  ),
                  const SizedBox(width: 8),
                  _PayButton(
                    label: 'Không thanh toán',
                    icon: Icons.money_off_rounded,
                    color: AppColors.error,
                    onTap: () => _handleCheckoutTap(
                      context,
                      ref,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckoutTap(
    BuildContext context,
    WidgetRef ref,
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
    // Resolve all dependencies and states from ref BEFORE deactivating (since deactivation disposes the widget!)
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
      // Pre-calculate values exactly like deactivateTableAndFreezeInvoice does to construct the local invoice
      final endTime = DateTime.now();
      final baseMinutes = endTime.difference(startTime).inMinutes + 1;
      final billedMinutes = ((baseMinutes + 4) ~/ 5) * 5;
      final playMinutes = billedMinutes + (tablesState.tableExtraPlayMinutes[table.id] ?? 0);
      final calcPlayAmount = (billedMinutes / 60.0) * rate + (tablesState.tableExtraPlayAmounts[table.id] ?? 0.0);
      
      final invProductTotal = products.fold(0.0,
          (sum, p) => sum + (p['price'] as double) * (p['qty'] as int));

      final invMemberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
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
        // Construct UnpaidInvoice using pre-calculated/frozen values (avoiding ref.read)
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
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tắt bàn vì gửi lệnh tắt đến Relay IoT thất bại.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else if (action == 'bypass') {
      if (context.mounted) {
        await _checkout(
          context,
          ref,
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
    WidgetRef ref,
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
    final finalPlayAmount = (billedMinutes / 60.0) * rate + (ref.read(tablesProvider).tableExtraPlayAmounts[table.id] ?? 0.0);
    final finalProductTotal =
        products.fold(0.0, (s, p) => s + (p['price'] as double) * (p['qty'] as int));
    
    final memberDiscountPercent = member != null ? (member['discount'] as num).toDouble() : 0.0;
    final playDiscountAmount = finalPlayAmount * (discountPlayPercent / 100.0);
    final serviceDiscountAmount = finalProductTotal * (discountServicePercent / 100.0);
    final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
    final billDiscountAmount = (finalPlayAmount + finalProductTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
    final finalDiscountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
    final finalNetTotal = (finalPlayAmount + finalProductTotal) - finalDiscountAmount;

    // Resolve Riverpod values and dependencies before await/dialog to prevent disposal issues
    final initialNote = ref.read(tablesProvider).tableNotes[table.id];
    final serverOrderId = ref.read(tablesProvider).tableServerOrderIds[table.id];
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

          final ok = await tablesNotifier.deactivateTable(table.id);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể tắt bàn vì gửi lệnh tắt đến Relay IoT thất bại.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
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
    
    final discountPlayPercent = invoice.discountPlayPercent;
    final discountServicePercent = invoice.discountServicePercent;
    final discountBillPercent = invoice.discountBillPercent;
    
    final playDiscountAmount = playAmount * (discountPlayPercent / 100.0);
    final serviceDiscountAmount = productTotal * (discountServicePercent / 100.0);
    final billDiscountPercentTotal = (discountBillPercent + memberDiscountPercent).clamp(0.0, 100.0);
    final billDiscountAmount = (playAmount + productTotal - playDiscountAmount - serviceDiscountAmount) * (billDiscountPercentTotal / 100.0);
    final discountAmount = playDiscountAmount + serviceDiscountAmount + billDiscountAmount;
    final netTotal = (playAmount + productTotal) - discountAmount;

    return Column(
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(height: 6),
              // Timer display (Static / Frozen)
              if (rate > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        if (member != null || discountPlayPercent > 0 || discountServicePercent > 0 || discountBillPercent > 0)
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
                          onTap: () => ref.read(tablesProvider.notifier).removeDiscount(invoice.id),
                          child: const Icon(Icons.cancel, size: 16, color: AppColors.accent),
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
                          onTap: () => ref.read(tablesProvider.notifier).removeDiscount(invoice.id),
                          child: const Icon(Icons.cancel, size: 16, color: AppColors.accent),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
          child: (products.isEmpty && (tablesState.tablePendingOrders[invoice.id]?.isEmpty ?? true))
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
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (products.isNotEmpty) ...[
                      if (tablesState.tablePendingOrders[invoice.id]?.isNotEmpty ?? false)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            'ĐÃ DUYỆT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ...products.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _ProductLineItem(
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
                            ),
                          )),
                    ],
                    if (tablesState.tablePendingOrders[invoice.id]?.isNotEmpty ?? false) ...[
                      Padding(
                        padding: EdgeInsets.only(
                          top: products.isNotEmpty ? 16.0 : 4.0,
                          bottom: 8.0,
                        ),
                        child: const Text(
                          'YÊU CẦU CHỜ DUYỆT (TỪ MOBILE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...(tablesState.tablePendingOrders[invoice.id] ?? []).map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PendingProductLineItem(
                              name: p['name'] as String,
                              qty: p['qty'] as int,
                              price: p['price'] as double,
                              onApprove: () => ref
                                  .read(tablesProvider.notifier)
                                  .approvePendingProduct(invoice.id, p['product_id'] as String),
                              onDeny: () => ref
                                  .read(tablesProvider.notifier)
                                  .denyPendingProduct(invoice.id, p['product_id'] as String),
                            ),
                          )),
                    ],
                  ],
                ),
        ),
        const Divider(height: 1),

        // ── Total & Payment ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Summary rows
              if (rate > 0)
                _SummaryRow('Tiền giờ chơi', _fmtCurrency(playAmount)),
              _SummaryRow('Dịch vụ', _fmtCurrency(productTotal)),
              if (discountPlayPercent > 0)
                _SummaryRow(
                  'Chiết khấu giờ chơi (${discountPlayPercent.toInt()}%)',
                  '-${_fmtCurrency(playDiscountAmount)}',
                ),
              if (discountServicePercent > 0)
                _SummaryRow(
                  'Chiết khấu dịch vụ (${discountServicePercent.toInt()}%)',
                  '-${_fmtCurrency(serviceDiscountAmount)}',
                ),
              if (discountBillPercent > 0 || memberDiscountPercent > 0)
                _SummaryRow(
                  memberDiscountPercent > 0
                      ? 'Chiết khấu HĐ & TV (${(discountBillPercent + memberDiscountPercent).toInt()}%)'
                      : 'Chiết khấu hóa đơn (${discountBillPercent.toInt()}%)',
                  '-${_fmtCurrency(billDiscountAmount)}',
                ),
              const Divider(height: 12),
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
              const SizedBox(height: 10),
              // Payment methods
              Row(
                children: [
                  _PayButton(
                    label: 'Thanh toán',
                    icon: Icons.payment_rounded,
                    color: AppColors.primary,
                    onTap: () => _checkoutUnpaid(
                      context,
                      ref,
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
                  ),
                  const SizedBox(width: 8),
                  _PayButton(
                    label: 'Không thanh toán',
                    icon: Icons.money_off_rounded,
                    color: AppColors.error,
                    onTap: () => _checkoutUnpaid(
                      context,
                      ref,
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
  ) {
    final currentUser = ref.read(currentUserProvider);
    final currentUserId = currentUser?.id ?? 'system';
    final currentShiftId = ref.read(currentShiftIdProvider) ?? 'shift-default';
    final localDb = ref.read(localDbServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    final tablesNotifier = ref.read(tablesProvider.notifier);

    return _checkoutUnpaidInvoice(
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
      },
    ),
  );
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

/// Trích xuất message lỗi từ Exception do ApiClient ném ra.
/// Exception('Sai thông tin') → 'Sai thông tin'
String _extractApiError(Object e) {
  final raw = e.toString();
  final match = RegExp(r'^Exception:\s*(.+)$').firstMatch(raw);
  return match?.group(1) ?? raw;
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

class _PendingProductLineItem extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const _PendingProductLineItem({
    required this.name,
    required this.qty,
    required this.price,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Chờ duyệt',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtCurrency(price)} x $qty',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmtCurrency(price * qty),
              style: AppTextStyles.labelLarge.copyWith(color: Colors.orange.shade900),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Duyệt',
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              onPressed: onApprove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Từ chối',
              icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
              onPressed: onDeny,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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

class MobileProductsNotificationDialog extends ConsumerWidget {
  const MobileProductsNotificationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tablesProvider);
    final notifications = state.mobileProductNotifications;

    if (notifications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actionsPadding: const EdgeInsets.only(bottom: 20, right: 24, left: 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Dịch vụ thêm từ Mobile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Có sản phẩm/dịch vụ mới được gọi từ ứng dụng điện thoại:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...notifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notification.tableName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          children: notification.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_right_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  Expanded(
                                    child: Text(
                                      item['name'] as String? ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'x${item['qty']}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              ref.read(tablesProvider.notifier).clearMobileProductNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ─── Helpers for Modbus RTU CRC16 & LCUS Protocol ─────────────────────────────

int _calculateModbusCRC(List<int> bytes) {
  int crc = 0xFFFF;
  for (int pos = 0; pos < bytes.length; pos++) {
    crc ^= bytes[pos];
    for (int i = 8; i != 0; i--) {
      if ((crc & 0x0001) != 0) {
        crc >>= 1;
        crc ^= 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc;
}

String _generateModbusCommand(int deviceId, int channel, bool turnOn) {
  final regHigh = 0;
  final regLow = (channel - 1).clamp(0, 255);
  final dataHigh = turnOn ? 0xFF : 0x00;
  final dataLow = 0x00;

  final bytes = [deviceId, 5, regHigh, regLow, dataHigh, dataLow];
  final crc = _calculateModbusCRC(bytes);
  final crcLow = crc & 0xFF;
  final crcHigh = (crc >> 8) & 0xFF;

  final allBytes = [...bytes, crcLow, crcHigh];
  return allBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('');
}

bool _isStandardModbus(IotConfigModel config, {int deviceId = 1}) {
  final expectedOn = _generateModbusCommand(deviceId, config.relayChannel, true);
  final expectedOff = _generateModbusCommand(deviceId, config.relayChannel, false);
  return config.commandOn.replaceAll(' ', '').toUpperCase() == expectedOn &&
         config.commandOff.replaceAll(' ', '').toUpperCase() == expectedOff;
}

String _generateLcusCommand(int channel, bool turnOn) {
  final start = 0xA0;
  final switchAddr = channel;
  final op = turnOn ? 0x01 : 0x00;
  final checksum = (start + switchAddr + op) & 0xFF;
  final bytes = [start, switchAddr, op, checksum];
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('');
}

bool _isStandardLcus(IotConfigModel config) {
  final expectedOn = _generateLcusCommand(config.relayChannel, true);
  final expectedOff = _generateLcusCommand(config.relayChannel, false);
  return config.commandOn.replaceAll(' ', '').toUpperCase() == expectedOn &&
         config.commandOff.replaceAll(' ', '').toUpperCase() == expectedOff;
}

// ─── Idle Table Details Panel ──────────────────────────────────────────────────

class _IdleTablePanel extends ConsumerWidget {
  final TableModel table;
  final TablesState tablesState;
  final VoidCallback onTogglePower;

  const _IdleTablePanel({
    required this.table,
    required this.tablesState,
    required this.onTogglePower,
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
    return '${buf.toString().split('').reversed.join('')} đ';
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'idle':
        bg = AppColors.successLight;
        fg = AppColors.success;
        text = 'Trống (Sẵn sàng)';
        break;
      case 'booked':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        text = 'Đặt trước';
        break;
      case 'maintenance':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        text = 'Đang bảo trì';
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        text = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(color: fg),
      ),
    );
  }

  Widget _buildIotStatusCard(BuildContext context, IotConfigModel? config) {
    if (config == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chưa cấu hình Relay IoT', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Đèn bàn sẽ không tự động bật/tắt khi bắt đầu/kết thúc tính giờ chơi.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final connInfo = config.connectionType == 'serial'
        ? 'Cổng Serial USB: ${config.port}'
        : 'Địa chỉ mạng LAN/Wifi: ${config.ipAddress}:${config.port}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                config.connectionType == 'serial' ? Icons.usb : Icons.lan,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.connectionType == 'serial' ? 'Kết nối USB Serial (COM)' : 'Kết nối TCP/IP LAN',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(connInfo, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kênh Relay', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 2),
                    Text('Cổng ${config.relayChannel}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lệnh bật', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 2),
                    Text(config.commandOn, style: AppTextStyles.mono.copyWith(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lệnh tắt', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 2),
                    Text(config.commandOff, style: AppTextStyles.mono.copyWith(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = (currentUser?.role.toLowerCase() ?? '').contains('admin') || currentUser?.role.toLowerCase() == 'manager';
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
    final rate = tablesState.getTableHourlyRate(table);
    final iotConfig = tablesState.iotConfigs[table.id];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(table.tableName, style: AppTextStyles.displayMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Loại bàn: ${typeModel.typeName}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tiền giờ: ${_fmtCurrency(rate)} /giờ',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(table.status),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          
          if (isAdmin) ...[
            Text('Cấu hình Relay tự động bật/tắt đèn', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _buildIotStatusCard(context, iotConfig),
          ],
          
          const Spacer(),
          
          if (isAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final currentUser = ref.read(currentUserProvider);
                      final role = currentUser?.role.toLowerCase() ?? '';
                      if (!role.contains('admin') && role != 'manager') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chỉ tài khoản Admin mới được cài đặt Relay IoT!'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (_) => IotConfigDialog(table: table, initialConfig: iotConfig),
                      );
                    },
                    icon: const Icon(Icons.settings_remote, size: 18),
                    label: const Text('Cài đặt Relay IoT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    final currentUser = ref.read(currentUserProvider);
                    final role = currentUser?.role.toLowerCase() ?? '';
                    if (!role.contains('admin') && role != 'manager') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chỉ tài khoản Admin mới được thay đổi trạng thái bảo trì!'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    ref.read(tablesProvider.notifier).setTableMaintenance(
                      table.id,
                      table.status != 'maintenance',
                    );
                  },
                  icon: Icon(
                    table.status == 'maintenance' ? Icons.check_circle_outline : Icons.build_outlined,
                    size: 18,
                  ),
                  label: Text(table.status == 'maintenance' ? 'Bỏ bảo trì' : 'Bảo trì'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    foregroundColor: table.status == 'maintenance' ? AppColors.success : AppColors.error,
                    side: BorderSide(
                      color: table.status == 'maintenance' ? AppColors.success : AppColors.error,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: table.status == 'maintenance' ? null : onTogglePower,
              icon: const Icon(Icons.power_settings_new_rounded, size: 20),
              label: const Text('Bật bàn chơi (Bắt đầu tính giờ)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── IoT Config Dialog ────────────────────────────────────────────────────────

class IotConfigDialog extends ConsumerStatefulWidget {
  final TableModel table;
  final IotConfigModel? initialConfig;
  
  const IotConfigDialog({
    super.key,
    required this.table,
    this.initialConfig,
  });

  @override
  ConsumerState<IotConfigDialog> createState() => _IotConfigDialogState();
}

class _IotConfigDialogState extends ConsumerState<IotConfigDialog> {
  String _connectionType = 'serial';
  String _selectedPort = 'COM1';
  int _relayChannel = 1;
  String _protocol = 'modbus'; // 'modbus', 'lcus', 'manual'
  
  bool _customPort = false;
  
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _tcpPortController = TextEditingController(text: '8080');
  final _customPortController = TextEditingController();
  final _deviceIdController = TextEditingController(text: '1');
  final _cmdOnController = TextEditingController();
  final _cmdOffController = TextEditingController();
  
  List<String> _availablePorts = [];
  bool _isLoadingPorts = false;
  bool _isTesting = false;
  String _testLog = '';

  @override
  void initState() {
    super.initState();
    _deviceIdController.addListener(_updateCommands);
    _loadAvailablePorts();
    _initValues();
  }

  @override
  void dispose() {
    _deviceIdController.removeListener(_updateCommands);
    _ipController.dispose();
    _tcpPortController.dispose();
    _customPortController.dispose();
    _deviceIdController.dispose();
    _cmdOnController.dispose();
    _cmdOffController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePorts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPorts = true;
    });
    try {
      final ports = SerialPort.availablePorts;
      if (!mounted) return;
      setState(() {
        _availablePorts = ports;
        _isLoadingPorts = false;
        if (ports.isNotEmpty && !_availablePorts.contains(_selectedPort)) {
          _selectedPort = ports.first;
          _updateCommands();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPorts = false;
      });
    }
  }

  void _initValues() {
    final cfg = widget.initialConfig;
    if (cfg != null) {
      _connectionType = cfg.connectionType;
      _relayChannel = cfg.relayChannel;
      
      if (cfg.connectionType == 'serial') {
        final port = cfg.port ?? 'COM1';
        _selectedPort = port;
        _customPortController.text = port;
        if (!_availablePorts.contains(port) && port.isNotEmpty) {
          _customPort = true;
        }
      } else {
        _ipController.text = cfg.ipAddress ?? '192.168.1.100';
        _tcpPortController.text = cfg.port ?? '8080';
      }

      if (_isStandardLcus(cfg)) {
        _protocol = 'lcus';
        _deviceIdController.text = '1';
        _updateCommands();
      } else {
        int matchedId = 1;
        bool isStandard = false;
        for (int i = 1; i <= 32; i++) {
          if (_isStandardModbus(cfg, deviceId: i)) {
            matchedId = i;
            isStandard = true;
            break;
          }
        }

        if (isStandard) {
          _protocol = 'modbus';
          _deviceIdController.text = matchedId.toString();
          _updateCommands();
        } else {
          _protocol = 'manual';
          _cmdOnController.text = cfg.commandOn;
          _cmdOffController.text = cfg.commandOff;
        }
      }
    } else {
      _connectionType = 'serial';
      _relayChannel = 1;
      _protocol = 'modbus';
      _updateCommands();
    }
  }

  void _updateCommands() {
    if (_protocol == 'manual') return;
    if (_protocol == 'lcus') {
      final cmdOn = _generateLcusCommand(_relayChannel, true);
      final cmdOff = _generateLcusCommand(_relayChannel, false);
      setState(() {
        _cmdOnController.text = cmdOn;
        _cmdOffController.text = cmdOff;
      });
    } else if (_protocol == 'modbus') {
      final devId = int.tryParse(_deviceIdController.text) ?? 1;
      final cmdOn = _generateModbusCommand(devId, _relayChannel, true);
      final cmdOff = _generateModbusCommand(devId, _relayChannel, false);
      setState(() {
        _cmdOnController.text = cmdOn;
        _cmdOffController.text = cmdOff;
      });
    }
  }

  void _appendLog(String text) {
    if (!mounted) return;
    setState(() {
      _testLog += '$text\n';
    });
  }

  Future<void> _runTest(bool turnOn) async {
    if (_isTesting) return;
    setState(() {
      _isTesting = true;
      _testLog = '🚀 Khởi tạo lệnh kiểm tra...\n';
    });

    final portVal = _connectionType == 'serial'
        ? (_customPort ? _customPortController.text : _selectedPort)
        : _tcpPortController.text;

    final testConfig = IotConfigModel(
      id: widget.table.id.hashCode,
      tableId: widget.table.id,
      connectionType: _connectionType,
      ipAddress: _connectionType == 'tcp_ip' ? _ipController.text : null,
      port: portVal,
      relayChannel: _relayChannel,
      commandOn: _cmdOnController.text,
      commandOff: _cmdOffController.text,
    );

    final tablesState = ref.read(tablesProvider);
    final useSim = tablesState.useSimulator;

    BilliardIoTController controller;
    if (useSim) {
      _appendLog('[Chế độ: GIẢ LẬP IoT]');
      controller = SimulatedBilliardIoTController();
    } else {
      _appendLog('[Chế độ: KẾT NỐI THỰC TẾ]');
      controller = RealBilliardIoTController();
    }

    final logSub = controller.logStream.listen((line) {
      _appendLog(line);
    });

    try {
      final target = _connectionType == 'serial' ? portVal : '${testConfig.ipAddress}:$portVal';
      _appendLog('Đang kết nối tới $target...');
      final connected = await controller.connect(testConfig);
      if (!connected) {
        _appendLog('❌ KẾT NỐI THẤT BẠI!');
        if (mounted) setState(() { _isTesting = false; });
        logSub.cancel();
        return;
      }

      _appendLog('✅ Kết nối thành công. Gửi lệnh...');
      final ok = turnOn ? await controller.turnOn() : await controller.turnOff();
      if (ok) {
        _appendLog('✅ Thực thi lệnh thành công!');
      } else {
        _appendLog('❌ Thực thi lệnh thất bại!');
      }

      await Future.delayed(const Duration(milliseconds: 600));
      _appendLog('Đang đóng kết nối...');
      await controller.disconnect();
      _appendLog('✅ Kết nối đã ngắt sạch sẽ.');
    } catch (e) {
      _appendLog('❌ LỖI HỆ THỐNG: $e');
    } finally {
      logSub.cancel();
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _save() {
    final portVal = _connectionType == 'serial'
        ? (_customPort ? _customPortController.text : _selectedPort)
        : _tcpPortController.text;

    if (_connectionType == 'tcp_ip' && _ipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng điền địa chỉ IP hợp lệ.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    if (portVal.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng điền cổng kết nối.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final cleanCmdOn = _cmdOnController.text.replaceAll(' ', '').trim();
    final cleanCmdOff = _cmdOffController.text.replaceAll(' ', '').trim();

    if (cleanCmdOn.isEmpty || cleanCmdOff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mã Hex bật/tắt không được bỏ trống.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final newConfig = IotConfigModel(
      id: widget.initialConfig?.id ?? widget.table.id.hashCode,
      tableId: widget.table.id,
      connectionType: _connectionType,
      ipAddress: _connectionType == 'tcp_ip' ? _ipController.text.trim() : null,
      port: portVal.trim(),
      relayChannel: _relayChannel,
      commandOn: cleanCmdOn,
      commandOff: cleanCmdOff,
    );

    ref.read(tablesProvider.notifier).updateIotConfig(widget.table.id, newConfig);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đã lưu cấu hình IoT cho bàn ${widget.table.tableName}'),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(tablesProvider);
    final isSim = tablesState.useSimulator;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_remote, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cấu hình Relay IoT - ${widget.table.tableName}', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 2),
                    Text('Thiết lập thông số kết nối và rơ-le để bật tắt đèn tự động', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _connectionType = 'serial';
                        _updateCommands();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _connectionType == 'serial' ? AppColors.primary.withOpacity(0.08) : Colors.white,
                        border: Border.all(
                          color: _connectionType == 'serial' ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.usb, color: _connectionType == 'serial' ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Cổng Serial (USB)',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: _connectionType == 'serial' ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _connectionType = 'tcp_ip';
                        _updateCommands();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _connectionType == 'tcp_ip' ? AppColors.primary.withOpacity(0.08) : Colors.white,
                        border: Border.all(
                          color: _connectionType == 'tcp_ip' ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lan, color: _connectionType == 'tcp_ip' ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Mạng TCP/IP LAN',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: _connectionType == 'tcp_ip' ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // IoT Simulator Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSim ? AppColors.successLight.withOpacity(0.4) : AppColors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSim ? AppColors.success : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSim ? Icons.sports_esports : Icons.router,
                    color: isSim ? AppColors.success : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chế độ giả lập IoT (Simulator)',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSim ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSim
                              ? 'Hệ thống giả lập tín hiệu rơ-le bật/tắt (khuyên dùng khi thử nghiệm)'
                              : 'Kết nối trực tiếp tới cổng COM/mạng TCP vật lý thực tế',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSim ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isSim,
                    activeColor: AppColors.success,
                    onChanged: (val) {
                      ref.read(tablesProvider.notifier).toggleSimulator(val);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_connectionType == 'serial') ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _customPort
                                ? TextField(
                                    controller: _customPortController,
                                    decoration: InputDecoration(
                                      labelText: 'Nhập cổng COM / Tên cổng USB',
                                      hintText: 'ví dụ: COM3 hoặc /dev/cu.usbserial...',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Chọn Cổng Serial', style: AppTextStyles.labelLarge),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.border),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: _availablePorts.contains(_selectedPort) ? _selectedPort : null,
                                                  hint: const Text('Chọn cổng...'),
                                                  isExpanded: true,
                                                  items: _availablePorts.map((port) {
                                                    return DropdownMenuItem<String>(
                                                      value: port,
                                                      child: Text(port),
                                                    );
                                                  }).toList(),
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setState(() {
                                                        _selectedPort = val;
                                                        _updateCommands();
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: _loadAvailablePorts,
                                            icon: _isLoadingPorts
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.refresh, color: AppColors.primary),
                                            tooltip: 'Tải lại danh sách cổng',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _customPort,
                                  onChanged: (v) {
                                    setState(() {
                                      _customPort = v ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _customPort = !_customPort;
                                      });
                                    },
                                    child: Text('Nhập thủ công', style: AppTextStyles.bodyMedium),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _ipController,
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ IP Relay',
                                hintText: 'ví dụ: 192.168.1.100',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _tcpPortController,
                              decoration: InputDecoration(
                                labelText: 'Cổng (TCP Port)',
                                hintText: 'ví dụ: 8080',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kênh Relay', style: AppTextStyles.labelLarge),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _relayChannel,
                                    isExpanded: true,
                                    items: List.generate(16, (index) => index + 1).map((ch) {
                                      return DropdownMenuItem<int>(
                                        value: ch,
                                        child: Text('Kênh $ch'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _relayChannel = val;
                                          _updateCommands();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Giao thức', style: AppTextStyles.labelLarge),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _protocol,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'modbus', child: Text('Modbus RTU')),
                                      DropdownMenuItem(value: 'lcus', child: Text('LCUS UART')),
                                      DropdownMenuItem(value: 'manual', child: Text('Tự nhập mã HEX')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _protocol = val;
                                          _updateCommands();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (_protocol == 'modbus') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _deviceIdController,
                          decoration: InputDecoration(
                            labelText: 'Địa chỉ thiết bị Modbus (Device ID)',
                            hintText: 'thường là 1',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _cmdOnController,
                      readOnly: _protocol != 'manual',
                      decoration: InputDecoration(
                        labelText: 'Mã HEX lệnh Bật đèn (ON Command)',
                        hintText: 'ví dụ: A00101A2 hoặc 01050000FF008C3A',
                        filled: _protocol != 'manual',
                        fillColor: _protocol != 'manual' ? AppColors.surfaceVariant : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: AppTextStyles.mono.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cmdOffController,
                      readOnly: _protocol != 'manual',
                      decoration: InputDecoration(
                        labelText: 'Mã HEX lệnh Tắt đèn (OFF Command)',
                        hintText: 'ví dụ: A00100A1 hoặc 010500000000CDCA',
                        filled: _protocol != 'manual',
                        fillColor: _protocol != 'manual' ? AppColors.surfaceVariant : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: AppTextStyles.mono.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    
                    Text('Chẩn đoán kết nối thử nghiệm', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Kiểm tra rơ-le tức thời ${isSim ? "(Đang bật Giả lập)" : "(Kết nối phần cứng thực tế)"}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : () => _runTest(true),
                          icon: const Icon(Icons.lightbulb, size: 16),
                          label: const Text('Bật đèn thử'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : () => _runTest(false),
                          icon: const Icon(Icons.lightbulb_outline, size: 16),
                          label: const Text('Tắt đèn thử'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    if (_testLog.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testLog,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            color: Colors.lightGreenAccent.shade400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Lưu cấu hình', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
