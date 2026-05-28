import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/providers.dart';
import '../tables/tables_provider.dart';
import '../sync/sync_provider.dart';
import '../../core/utils/string_utils.dart';

// ─── Emoji mapping helpers ─────────────────────────────────────────────────────

String _resolveEmoji(Map<String, dynamic> product) {
  /*
  final name = (product['name'] as String? ?? '').toLowerCase();
  final category = (product['category'] as String? ?? '').toLowerCase();

  // Đồ uống
  if (name.contains('bia') || name.contains('beer')) return '🍺';
  if (name.contains('red bull') || name.contains('redbull')) return '⚡';
  if (name.contains('trà') || name.contains('tea')) return '🍵';
  if (name.contains('cà phê') || name.contains('coffee')) return '☕';
  if (name.contains('nước lọc') || name.contains('aquafina') || name.contains('lavie')) return '💧';
  if (name.contains('coca') || name.contains('pepsi') || name.contains('sprite')) return '🥤';
  if (name.contains('sting') || name.contains('rockstar')) return '🥤';
  if (name.contains('sữa') || name.contains('milk')) return '🥛';
  if (name.contains('nước')) return '🥤';

  // Đồ ăn
  if (name.contains('mì') || name.contains('phở') || name.contains('bún')) return '🍜';
  if (name.contains('bánh mì') || name.contains('sandwich')) return '🥪';
  if (name.contains('snack') || name.contains('bim bim') || name.contains('khoai')) return '🍿';
  if (name.contains('cơm')) return '🍱';
  if (name.contains('gà') || name.contains('chicken')) return '🍗';
  if (name.contains('bò') || name.contains('beef')) return '🥩';
  if (name.contains('pizza')) return '🍕';
  if (name.contains('burger') || name.contains('hamburger')) return '🍔';

  // Thuốc lá
  if (name.contains('thuốc lá') || name.contains('cigarette') || name.contains('marlboro') || name.contains('du lịch')) return '🚬';
  if (category.contains('thuốc')) return '🚬';

  // Phụ kiện billiard
  if (name.contains('găng') || name.contains('glove')) return '🧤';
  if (name.contains('cơ') || name.contains('cue')) return '🎱';
  if (name.contains('phấn') || name.contains('chalk')) return '🟦';

  // Fallback theo category
  if (category.contains('uống') || category.contains('drink') || category.contains('beverage')) return '🥤';
  if (category.contains('ăn') || category.contains('food')) return '🍜';
  if (category.contains('thuốc')) return '🚬';
  */

  return '🛍️';
}

/// Map từ API schema → UI schema thống nhất
Map<String, dynamic> _mapProductFields(Map<String, dynamic> raw, [Map<String, String> catMap = const {}]) {
  final catIdStr = raw['category_id']?.toString();
  final catName = catMap[catIdStr] ?? raw['category_name'] as String? ?? raw['category'] as String? ?? 'Khác';
  return {
    'id': raw['id']?.toString() ?? raw['product_id']?.toString() ?? '',
    'name': raw['product_name'] as String? ?? raw['name'] as String? ?? '—',
    'price': double.tryParse(raw['selling_price']?.toString() ?? raw['price']?.toString() ?? '') ?? 0.0,
    'category': catName,
    'barcode': raw['barcode']?.toString() ?? '',
  };
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class AddProductPanel extends ConsumerStatefulWidget {
  final String tableId;
  const AddProductPanel({super.key, required this.tableId});

  @override
  ConsumerState<AddProductPanel> createState() => _AddProductPanelState();
}

class _AddProductPanelState extends ConsumerState<AddProductPanel> {
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<String> _categoryNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final localDb = ref.read(localDbServiceProvider);
      final cachedCats = await localDb.getCachedProductCategories();
      final cached = await localDb.getCachedProducts();
      
      final catMap = {
        for (final c in cachedCats)
          c['id']?.toString() ?? '': c['category_name'] as String? ?? 'Khác'
      };

      final mapped = cached.map((p) => _mapProductFields(p, catMap)).toList();
      final categoryNames = cachedCats
          .map((c) => c['category_name'] as String? ?? 'Khác')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _products = mapped;
          _categoryNames = categoryNames;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading products from local DB: $e\n$stack');
      if (mounted) {
        setState(() {
          _products = [];
          _categoryNames = [];
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _categories {
    if (_categoryNames.isNotEmpty) {
      return ['Tất cả', ..._categoryNames];
    }
    final cats = _products.map((p) => p['category'] as String).toSet().toList()
      ..sort();
    return ['Tất cả', ...cats];
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final normalizedQuery = removeDiacritics(_searchQuery).toLowerCase();
    return _products.where((p) {
      final matchCategory =
          _selectedCategory == 'Tất cả' || p['category'] == _selectedCategory;
      if (!matchCategory) return false;

      if (_searchQuery.isEmpty) return true;

      final name = p['name'] as String? ?? '';
      final barcode = p['barcode'] as String? ?? '';

      final normalizedName = removeDiacritics(name).toLowerCase();
      final normalizedBarcode = removeDiacritics(barcode).toLowerCase();

      return normalizedName.contains(normalizedQuery) ||
             normalizedBarcode.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe syncStateProvider → reload khi sync hoàn tất hoặc cache bị xóa
    ref.listen<SyncState>(syncStateProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;
      final doneSyncing = wasSyncing && !next.isSyncing;
      if (doneSyncing) {
        _loadProducts();
        // Reset về "Tất cả" phòng category cũ không còn hợp lệ
        setState(() => _selectedCategory = 'Tất cả');
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search + Category header ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: Colors.white,
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          })
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Category filter – động từ dữ liệu thực tế
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Product Grid ─────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text('Không có sản phẩm',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        itemCount: _filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 160,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (ctx, i) {
                          final product = _filteredProducts[i];
                          final emoji = _resolveEmoji(product);
                          return _ProductCard(
                            product: {...product, 'emoji': emoji},
                            onAdd: () {
                              ref
                                  .read(tablesProvider.notifier)
                                  .addProductToTable(
                                widget.tableId,
                                {
                                  'product_id': product['id'],
                                  'name': product['name'],
                                  'price': product['price'],
                                  'qty': 1,
                                },
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Đã thêm ${product['name']} vào hóa đơn'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                                width: 280,
                              ));
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAdd;
  const _ProductCard({required this.product, required this.onAdd});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onAdd();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.product['emoji'] as String,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.product['name'] as String,
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fmtCurrency(widget.product['price'] as double),
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: AppColors.primary),
                    SizedBox(width: 2),
                    Text('Thêm',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
