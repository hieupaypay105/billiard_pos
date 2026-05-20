import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_item_model.dart';

class QuanTriListResponse {
  const QuanTriListResponse({
    required this.items,
    required this.pagination,
  });

  factory QuanTriListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final items = <QuanTriItemModel>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(QuanTriItemModel.fromJson(item));
      }
    }

    return QuanTriListResponse(
      items: items,
      pagination: QuanTriPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final List<QuanTriItemModel> items;
  final QuanTriPagination pagination;
}

class QuanTriPagination {
  const QuanTriPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory QuanTriPagination.fromJson(Map<String, dynamic> json) {
    return QuanTriPagination(
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
