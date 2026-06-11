import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'tables_provider.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(tablesProvider.notifier).loadTables();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tablesProvider);
    final isDataEmpty = state.tables.isEmpty && state.tableTypes.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bàn'),
        centerTitle: true,
      ),
      body: state.isLoading && isDataEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildTabbedContent(context, state),
    );
  }

  Widget _buildTabbedContent(BuildContext context, TablesState state) {
    if (state.tableTypes.isEmpty) {
      return _buildGrid(context, state.tables, state);
    }

    return DefaultTabController(
      key: ValueKey(state.tableTypes.length),
      length: state.tableTypes.length + 1, // +1 for "Tất cả" (All tabs)
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: 'Tất cả'),
                ...state.tableTypes.map((type) => Tab(text: type.typeName)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGrid(context, state.tables, state),
                ...state.tableTypes.map((type) {
                  final filteredTables = state.tables
                      .where((t) => t.tableTypeId == type.id)
                      .toList();
                  return _buildGrid(context, filteredTables, state);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List tables, TablesState state) {
    if (tables.isEmpty) {
      return Center(
        child: Text(
          'Không có bàn nào.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tablesProvider.notifier).loadTables(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          final isActive = table.status == 'active';
          
          return InkWell(
            onTap: () {
              // Navigate to Table detail / order screen
              // context.push('/table/${table.id}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_bar,
                    size: 40,
                    color: isActive ? AppColors.primary : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    table.tableName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isActive ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Đang chơi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bàn trống',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
