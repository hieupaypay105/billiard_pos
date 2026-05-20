class CongTacVienFilter {
  const CongTacVienFilter({
    this.keyword,
    this.status,
    this.saleId,
    this.page = 1,
    this.perPage = 50,
    this.sortBy,
    this.order,
  });

  factory CongTacVienFilter.fromJson(Map<String, dynamic> json) {
    return CongTacVienFilter(
      keyword: json['keyword'] as String?,
      status: json['status'] as int?,
      saleId: json['saleId'] as String?,
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 50,
      sortBy: json['sortBy'] as String?,
      order: json['order'] as String?,
    );
  }

  final String? keyword;
  final int? status;
  final String? saleId;
  final int page;
  final int perPage;
  final String? sortBy;
  final String? order;

  Map<String, dynamic> toQueryParams() {
    return {
      if (keyword != null && keyword!.isNotEmpty) 'keyword': keyword,
      if (status != null) 'status': '$status',
      if (saleId != null && saleId!.isNotEmpty) 'sale_id': saleId,
      'page': '$page',
      'per_page': '$perPage',
      if (sortBy != null && sortBy!.isNotEmpty) 'sort_by': sortBy,
      if (order != null && order!.isNotEmpty) 'order': order,
    };
  }

  CongTacVienFilter copyWith({
    String? keyword,
    int? status,
    String? saleId,
    int? page,
    int? perPage,
    String? sortBy,
    String? order,
  }) {
    return CongTacVienFilter(
      keyword: keyword ?? this.keyword,
      status: status ?? this.status,
      saleId: saleId ?? this.saleId,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'status': status,
      'saleId': saleId,
      'page': page,
      'perPage': perPage,
      'sortBy': sortBy,
      'order': order,
    };
  }
}
