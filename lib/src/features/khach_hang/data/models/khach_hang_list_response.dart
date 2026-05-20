import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_item_model.dart';

class KhachHangListResponse {
  const KhachHangListResponse({
    required this.items,
    required this.pagination,
    this.dataStatus = const {},
  });

  factory KhachHangListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final items = <KhachHangItemModel>[];
    for (final group in rawItems) {
      if (group is List) {
        for (final item in group) {
          if (item is Map<String, dynamic>) {
            items.add(KhachHangItemModel.fromJson(item));
          }
        }
      } else if (group is Map<String, dynamic>) {
        items.add(KhachHangItemModel.fromJson(group));
      }
    }

    return KhachHangListResponse(
      items: items,
      pagination: KhachHangPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
      dataStatus: _parseDataStatus(json['data_status']),
    );
  }

  static Map<int, int> _parseDataStatus(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (int.tryParse(entry.key.toString()) != null)
          int.parse(entry.key.toString()):
              int.tryParse(entry.value.toString()) ?? 0,
    };
  }

  final List<KhachHangItemModel> items;
  final KhachHangPagination pagination;

  /// Status index → count, e.g. {0: 338, 1: 554, 2: 48, ...}
  final Map<int, int> dataStatus;
}

class KhachHangPagination {
  const KhachHangPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory KhachHangPagination.fromJson(Map<String, dynamic> json) {
    return KhachHangPagination(
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

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
