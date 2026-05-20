import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_item_model.dart';

class CongTacVienListResponse {
  const CongTacVienListResponse({
    required this.items,
    required this.pagination,
  });

  factory CongTacVienListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final items = <CongTacVienItemModel>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(CongTacVienItemModel.fromJson(item));
      }
    }

    return CongTacVienListResponse(
      items: items,
      pagination: CongTacVienPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final List<CongTacVienItemModel> items;
  final CongTacVienPagination pagination;
}

class CongTacVienPagination {
  const CongTacVienPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory CongTacVienPagination.fromJson(Map<String, dynamic> json) {
    return CongTacVienPagination(
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
