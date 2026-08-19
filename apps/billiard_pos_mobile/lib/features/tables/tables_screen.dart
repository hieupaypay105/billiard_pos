import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/desktop_update_banner.dart';
import 'tables_provider.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen>
    with DesktopUpdateBannerMixin {
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
    // Listen for desktop notifications
    ref.listen<TablesState>(tablesProvider, (previous, next) {
      handleDesktopNotification(previous, next);
    });

    final state = ref.watch(tablesProvider);
    final isDataEmpty = state.tables.isEmpty && state.tableTypes.isEmpty;

    return buildDesktopBannerOverlay(
      Scaffold(
        appBar: AppBar(
          title: const Text('Danh sách bàn'),
          centerTitle: true,
        ),
        body: state.isLoading && isDataEmpty
            ? const Center(child: CircularProgressIndicator())
            : _buildTabbedContent(context, state),
      ),
    );
  }

  Widget _buildTabbedContent(BuildContext context, TablesState state) {
    if (state.tableTypes.isEmpty) {
      return _buildGrid(context, state.tables, state);
    }

    return DefaultTabController(
      key: ValueKey(state.tableTypes.length),
      length: state.tableTypes.length,
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
              tabs: state.tableTypes.map((type) => Tab(text: type.typeName)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: state.tableTypes.map((type) {
                final filteredTables = state.tables
                    .where((t) => t.tableTypeId == type.id)
                    .toList();
                return _buildGrid(context, filteredTables, state);
              }).toList(),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentHeight = constraints.maxHeight;
        final parentWidth = constraints.maxWidth;
        
        final rowCount = (tables.length / 2).ceil();
        
        // Grid padding & spacing
        const paddingVal = 16.0;
        const spacingVal = 16.0;
        
        // Calculate item width
        final availableWidth = parentWidth - (paddingVal * 2) - spacingVal;
        final itemWidth = availableWidth / 2;
        
        // Calculate item height
        final verticalPaddingAndSpacing = (paddingVal * 2) + ((rowCount - 1) * spacingVal);
        final availableHeight = parentHeight - verticalPaddingAndSpacing;
        
        double childAspectRatio = 1.1; // fallback default
        double computedHeight = 120.0;
        bool fitsScreen = false;
        
        if (availableHeight > 0 && rowCount > 0) {
          computedHeight = availableHeight / rowCount;
          // Cap the maximum height of cards if there are very few rows (so they don't stretch abnormally)
          if (computedHeight > 150.0) {
            computedHeight = 150.0;
          }
          // Set a minimum height threshold to avoid extremely squished cards
          if (computedHeight >= 90) {
            childAspectRatio = itemWidth / computedHeight;
            fitsScreen = true;
          }
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(tablesProvider.notifier).loadTables(),
          child: GridView.builder(
            padding: const EdgeInsets.all(paddingVal),
            physics: fitsScreen 
                ? const NeverScrollableScrollPhysics() 
                : const AlwaysScrollableScrollPhysics(), // Scroll only if row count is too large
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacingVal,
              mainAxisSpacing: spacingVal,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final isActive = table.status == 'active';
              final isMaintenance = table.status == 'maintenance';
              
              // Scale components if the cards are compressed
              final isCompact = computedHeight < 125;
              final iconSize = isCompact ? 30.0 : 40.0;
              final titleSize = isCompact ? 15.0 : 18.0;
              final spacing = isCompact ? 4.0 : 8.0;
              
              final pendingCount = state.tablePendingOrders[table.id]?.length ?? 0;
              
              return InkWell(
                onTap: () {
                  if (isMaintenance) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bàn đang bảo trì, không thể sử dụng!'),
                        backgroundColor: AppColors.tableMaintenanceAccent,
                      ),
                    );
                    return;
                  }
                  context.push('${AppRoutes.billing}/${table.id}');
                },
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isActive 
                            ? AppColors.primary.withValues(alpha: 0.1) 
                            : (isMaintenance 
                                ? AppColors.tableMaintenance 
                                : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive 
                              ? AppColors.primary 
                              : (isMaintenance 
                                  ? AppColors.tableMaintenanceAccent 
                                  : Colors.grey.shade300),
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
                            isMaintenance ? Icons.build : Icons.table_bar,
                            size: iconSize,
                            color: isActive 
                                ? AppColors.primary 
                                : (isMaintenance 
                                    ? AppColors.tableMaintenanceAccent 
                                    : Colors.grey.shade400),
                          ),
                          SizedBox(height: spacing),
                          Text(
                            table.tableName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleSize,
                              color: isActive 
                                  ? AppColors.primary 
                                  : (isMaintenance 
                                      ? AppColors.tableMaintenanceAccent 
                                      : Colors.black87),
                            ),
                          ),
                          if (isActive) ...[
                            SizedBox(height: spacing),
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
                          ] else if (isMaintenance) ...[
                            SizedBox(height: spacing),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.tableMaintenanceAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Bảo trì',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(height: spacing),
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
                    if (pendingCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
