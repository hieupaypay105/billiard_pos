import 'dart:async';

import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_column_def.dart';
import 'package:flutter/material.dart';

/// Reusable data table widget matching Figma Frame 503 design.
///
/// Generic [T] represents the data type for each row.
///
/// ```dart
/// AnDataTable<PropertyItem>(
///   columns: [
///     AnColumnDef(key: 'stt', label: 'STT', valueGetter: (e) => e.stt),
///     AnColumnDef(key: 'code', label: 'Mã căn', valueGetter: (e) => e.code),
///   ],
///   items: propertyList,
///   actionsBuilder: (item, i) => Row(children: [editBtn, deleteBtn]),
/// )
/// ```
class AnDataTable<T> extends StatelessWidget {
  const AnDataTable({
    required this.columns,
    required this.items,
    super.key,
    this.rowHeight = 40,
    this.headerHeight = 44,
    this.actionsBuilder,
    this.actionsColumnWidth = 80,
    this.actionsLabel = 'Edit',
    this.onSort,
    this.sortColumnKey,
    this.sortAscending = true,
    this.onFilterTap,
    this.scrollController,
    this.headerDecoration,
    this.headerTextStyle,
    this.rowDecorationBuilder,
    this.cellTextStyle,
    this.onRowTap,
    this.listPadding,
    this.headerCellPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.cellPadding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    this.shrinkWrapList = false,
    this.horizontalScrollPadding = 8.0,
  });

  /// Horizontal padding for the inner horizontal scroll view. Default: 8.0.
  final double horizontalScrollPadding;

  /// Column definitions.
  final List<AnColumnDef<T>> columns;

  /// Data source.
  final List<T> items;

  /// Row height. Default: 40.
  final double rowHeight;

  /// Header height. Default: 44.
  final double headerHeight;

  /// Builder for action buttons per row (Edit/Delete).
  /// If null, no action column is shown.
  final Widget Function(T item, int index)? actionsBuilder;

  /// Width of the action column. Default: 80.
  final double actionsColumnWidth;

  /// Label for the actions column header. Default: 'Edit'.
  final String actionsLabel;

  /// Called when a sortable column header is tapped.
  /// Parameters: columnKey - the key of the tapped column, ascending - sort direction.
  final void Function(String columnKey, {required bool ascending})? onSort;

  /// Current sort column key. Null if not sorted.
  final String? sortColumnKey;

  /// Sort direction. True = ascending.
  final bool sortAscending;

  /// Called when a filterable column header is tapped.
  final void Function(String columnKey)? onFilterTap;

  /// Optional ScrollController for the vertical list view.
  final ScrollController? scrollController;

  /// Optional background decoration for the header row.
  final BoxDecoration? headerDecoration;

  /// Optional text style for the header row.
  final TextStyle? headerTextStyle;

  /// Optional builder for row decoration based on index.
  final BoxDecoration Function(int index)? rowDecorationBuilder;

  /// Optional text style for standard data cells.
  final TextStyle? cellTextStyle;

  /// Called when a data row is tapped.
  final void Function(T item, int index)? onRowTap;

  /// Optional padding for the inner list view.
  final EdgeInsetsGeometry? listPadding;

  /// Optional horizontal/vertical padding for header cells.
  final EdgeInsetsGeometry headerCellPadding;

  /// Optional padding for data cells.
  final EdgeInsetsGeometry cellPadding;

  /// Whether the inner list view should shrink wrap its content without Expanded wrapper.
  final bool shrinkWrapList;

  double get _totalWidth {
    double w = 0;
    for (final col in columns) {
      w += col.width ?? 100;
    }
    if (actionsBuilder != null) w += actionsColumnWidth;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final Widget listWidget = ListView.builder(
      controller: scrollController,
      padding: listPadding ?? EdgeInsets.zero,
      physics: shrinkWrapList
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      shrinkWrap: shrinkWrapList,
      itemCount: items.length,
      itemBuilder: (ctx, index) => _buildRow(context, items[index], index),
    );

    final list = shrinkWrapList ? listWidget : Expanded(child: listWidget);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalScrollPadding),
      child: SizedBox(
        width: _totalWidth + 2.0, // Account for left and right borders
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            list,
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: headerHeight,
      decoration:
          headerDecoration ??
          const BoxDecoration(
            color: AppColors.tableHeaderBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
      child: Row(
        children: [
          ...columns.map((col) => _buildHeaderCell(context, col)),
          if (actionsBuilder != null)
            SizedBox(
              width: actionsColumnWidth,
              child: Center(
                child: Text(
                  actionsLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, AnColumnDef<T> col) {
    final isSorted = sortColumnKey == col.key;

    Widget content;
    switch (col.type) {
      case AnColumnType.text:
        content = Text(
          col.label.toUpperCase(),
          style:
              headerTextStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        );
      case AnColumnType.sortable:
        content = GestureDetector(
          onTap: () {
            if (onSort == null) return;
            final newAscending = !isSorted || !sortAscending;
            onSort!(col.key, ascending: newAscending);
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  col.label.toUpperCase(),
                  style:
                      headerTextStyle ??
                      const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.swap_vert,
                size: 16,
                color: isSorted ? AppColors.primaryGold : Colors.white70,
              ),
            ],
          ),
        );
      case AnColumnType.filterable:
        content = GestureDetector(
          onTap: () => onFilterTap?.call(col.key),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  col.label.toUpperCase(),
                  style:
                      headerTextStyle ??
                      const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Colors.white70,
              ),
            ],
          ),
        );
    }

    return SizedBox(
      width: col.width ?? 100,
      child: Padding(
        padding: headerCellPadding,
        child: Align(
          alignment: _textAlignToAlignment(col.textAlign),
          child: content,
        ),
      ),
    );
  }

  // ─── Data Row ─────────────────────────────────────────────

  Widget _buildRow(BuildContext context, T item, int index) {
    final row = Container(
      height: rowHeight,
      decoration:
          rowDecorationBuilder?.call(index) ??
          const BoxDecoration(
            color: AppColors.dashboardBgStart,
            border: Border(
              bottom: BorderSide(color: AppColors.tableCardBorder),
            ),
          ),
      child: Row(
        children: [
          ...columns.map((col) => _buildDataCell(context, col, item, index)),
          if (actionsBuilder != null)
            SizedBox(
              width: actionsColumnWidth,
              child: Center(child: actionsBuilder!(item, index)),
            ),
        ],
      ),
    );

    if (onRowTap == null) return row;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onRowTap!(item, index),
      child: row,
    );
  }

  Widget _buildDataCell(
    BuildContext context,
    AnColumnDef<T> col,
    T item,
    int index,
  ) {
    Widget child;
    if (col.cellBuilder != null) {
      child = col.cellBuilder!(item, index);
    } else {
      child = Text(
        col.valueGetter(item),
        style:
            cellTextStyle ??
            const TextStyle(fontSize: 10, color: AppColors.textDark),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: col.textAlign,
      );
    }

    return SizedBox(
      width: col.width ?? 100,
      child: Padding(
        padding: cellPadding,
        child: Align(
          alignment: _textAlignToAlignment(col.textAlign),
          child: child,
        ),
      ),
    );
  }

  // ─── Utils ────────────────────────────────────────────────

  Alignment _textAlignToAlignment(TextAlign textAlign) {
    return switch (textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }
}

/// Skeleton loading state for [AnDataTable].
class AnDataTableSkeleton<T> extends StatelessWidget {
  const AnDataTableSkeleton({
    required this.columns,
    super.key,
    this.rowCount = 8,
    this.rowHeight = 40,
    this.headerHeight = 44,
    this.actionsColumnWidth = 80,
    this.actionsLabel = 'Edit',
    this.actionsCount = 0,
    this.headerDecoration,
    this.headerTextStyle,
    this.rowDecorationBuilder,
    this.listPadding,
    this.headerCellPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.cellPadding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    this.shrinkWrapList = false,
  });

  final List<AnColumnDef<T>> columns;
  final int rowCount;
  final double rowHeight;
  final double headerHeight;
  final double actionsColumnWidth;
  final String actionsLabel;
  final int actionsCount;
  final BoxDecoration? headerDecoration;
  final TextStyle? headerTextStyle;
  final BoxDecoration Function(int index)? rowDecorationBuilder;
  final EdgeInsetsGeometry? listPadding;
  final EdgeInsetsGeometry headerCellPadding;
  final EdgeInsetsGeometry cellPadding;
  final bool shrinkWrapList;

  bool get _hasActions => actionsCount > 0;

  double get _totalWidth {
    double width = 0;
    for (final col in columns) {
      width += col.width ?? 100;
    }
    if (_hasActions) width += actionsColumnWidth;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final Widget listWidget = SingleChildScrollView(
      physics: shrinkWrapList
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      padding: listPadding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rowCount, _buildRow),
      ),
    );

    final list = shrinkWrapList ? listWidget : Expanded(child: listWidget);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        width: _totalWidth + 2.0, // Account for left and right borders
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            list,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: headerHeight,
      decoration:
          headerDecoration ??
          const BoxDecoration(
            color: AppColors.tableHeaderBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
      child: Row(
        children: [
          ...columns.map(_buildHeaderCell),
          if (_hasActions)
            SizedBox(
              width: actionsColumnWidth,
              child: Center(
                child: Text(
                  actionsLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(AnColumnDef<T> col) {
    Widget content;
    switch (col.type) {
      case AnColumnType.text:
        content = Text(
          col.label.toUpperCase(),
          style:
              headerTextStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
          overflow: TextOverflow.ellipsis,
        );
      case AnColumnType.sortable:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                col.label.toUpperCase(),
                style:
                    headerTextStyle ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.swap_vert, size: 16, color: Colors.white70),
          ],
        );
      case AnColumnType.filterable:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                col.label.toUpperCase(),
                style:
                    headerTextStyle ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white70),
          ],
        );
    }

    return SizedBox(
      width: col.width ?? 100,
      child: Padding(
        padding: headerCellPadding,
        child: Align(
          alignment: _textAlignToAlignment(col.textAlign),
          child: content,
        ),
      ),
    );
  }

  Widget _buildRow(int index) {
    return Container(
      height: rowHeight,
      decoration:
          rowDecorationBuilder?.call(index) ??
          const BoxDecoration(
            color: AppColors.dashboardBgStart,
            border: Border(
              bottom: BorderSide(color: AppColors.tableBorder, width: 0.5),
            ),
          ),
      child: Row(
        children: [
          ...columns.map(_buildDataCell),
          if (_hasActions)
            SizedBox(
              width: actionsColumnWidth,
              child: Center(
                child: _TableActionSkeleton(actionsCount: actionsCount),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataCell(AnColumnDef<T> col) {
    final cellWidth = col.width ?? 100.0;
    final maxPlaceholderWidth = (cellWidth - 16).clamp(0.0, double.infinity);
    final minPlaceholderWidth = maxPlaceholderWidth < 28
        ? maxPlaceholderWidth
        : 28.0;
    final placeholderWidth = (cellWidth * 0.6).clamp(
      minPlaceholderWidth,
      maxPlaceholderWidth,
    );

    return SizedBox(
      width: cellWidth,
      child: Padding(
        padding: cellPadding,
        child: Align(
          alignment: _textAlignToAlignment(col.textAlign),
          child: _TableSkeletonShimmer(
            child: _TableSkeletonBox(
              width: placeholderWidth,
              height: 12,
            ),
          ),
        ),
      ),
    );
  }

  Alignment _textAlignToAlignment(TextAlign textAlign) {
    return switch (textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }
}

class _TableActionSkeleton extends StatelessWidget {
  const _TableActionSkeleton({required this.actionsCount});

  final int actionsCount;

  @override
  Widget build(BuildContext context) {
    return _TableSkeletonShimmer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(actionsCount, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == actionsCount - 1 ? 0 : 4),
            child: const _TableSkeletonBox(width: 18, height: 18, radius: 9),
          );
        }),
      ),
    );
  }
}

class _TableSkeletonShimmer extends StatefulWidget {
  const _TableSkeletonShimmer({required this.child});

  final Widget child;

  @override
  State<_TableSkeletonShimmer> createState() => _TableSkeletonShimmerState();
}

class _TableSkeletonShimmerState extends State<_TableSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - 0.5 + (t * 2.0), -0.2),
              end: Alignment(1.0 + (t * 2.0), 0.2),
              colors: const [
                Color(0xFF3B3537),
                Color(0xFF4B4547),
                Color(0xFF3B3537),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _TableSkeletonBox extends StatelessWidget {
  const _TableSkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF645E5A),
      ),
    );
  }
}
