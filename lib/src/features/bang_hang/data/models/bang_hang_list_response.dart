import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_item_model.dart';

class BangHangListResponse {
  const BangHangListResponse({
    required this.items,
    required this.pagination,
  });

  factory BangHangListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    // API returns nested array: items = [[item1], [item2]]
    final items = <BangHangItemModel>[];
    for (final group in rawItems) {
      if (group is List) {
        for (final item in group) {
          if (item is Map<String, dynamic>) {
            items.add(BangHangItemModel.fromJson(item));
          }
        }
      } else if (group is Map<String, dynamic>) {
        items.add(BangHangItemModel.fromJson(group));
      }
    }

    return BangHangListResponse(
      items: items,
      pagination: BangHangPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final List<BangHangItemModel> items;
  final BangHangPagination pagination;
}

class BangHangPagination {
  const BangHangPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory BangHangPagination.fromJson(Map<String, dynamic> json) {
    return BangHangPagination(
      total: _parseInt(json['total']),
      perPage: _parseInt(json['per_page']),
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
    );
  }

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  static int _parseInt(value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
