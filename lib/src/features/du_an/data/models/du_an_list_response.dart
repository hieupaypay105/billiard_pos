import 'package:anholding_app/src/features/du_an/data/models/du_an_item_model.dart';

class DuAnListResponse {
  const DuAnListResponse({
    required this.items,
    required this.pagination,
  });

  factory DuAnListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final items = <DuAnItemModel>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(DuAnItemModel.fromJson(item));
      }
    }

    return DuAnListResponse(
      items: items,
      pagination: DuAnPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final List<DuAnItemModel> items;
  final DuAnPagination pagination;
}

class DuAnPagination {
  const DuAnPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory DuAnPagination.fromJson(Map<String, dynamic> json) {
    return DuAnPagination(
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
