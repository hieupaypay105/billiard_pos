import 'package:equatable/equatable.dart';

/// Domain value object representing filter criteria for customer list queries.
class KhachHangFilter extends Equatable {
  const KhachHangFilter({
    this.projectId = const [],
    this.area = const [],
    this.type = const [],
    this.financialRange = const [],
    this.sourceId = const [],
    this.saleId = const [],
    this.status = const [],
    this.keyword = '',
    this.createdAt = '',
    this.customerType = 'personal',
    this.page = 1,
    this.perPage = 50,
  });

  factory KhachHangFilter.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(Object? value, T Function(Object?) parse) {
      if (value is! List) return const [];
      return value.map(parse).whereType<T>().toList();
    }

    int? parseInt(Object? v) => v == null ? null : int.tryParse(v.toString());

    return KhachHangFilter(
      projectId: parseList(json['project_id'], parseInt).nonNulls.toList(),
      area: parseList<String>(
        json['area'],
        (v) => v == null ? '' : v.toString(),
      ).where((s) => s.isNotEmpty).toList(),
      type: parseList<String>(
        json['type'],
        (v) => v == null ? '' : v.toString(),
      ).where((s) => s.isNotEmpty).toList(),
      financialRange: parseList<String>(
        json['financial_range'],
        (v) => v == null ? '' : v.toString(),
      ).where((s) => s.isNotEmpty).toList(),
      sourceId: parseList(json['source_id'], parseInt).nonNulls.toList(),
      saleId: parseList(json['sale_id'], parseInt).nonNulls.toList(),
      status: parseList(json['status'], parseInt).nonNulls.toList(),
      keyword: json['keyword']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  final List<int> projectId;
  final List<String> area;
  final List<String> type;
  final List<String> financialRange;
  final List<int> sourceId;
  final List<int> saleId;
  final List<int> status;
  final String keyword;
  final String createdAt;
  final String customerType;
  final int page;
  final int perPage;

  Map<String, dynamic> toPayload() {
    return {
      'project_id': projectId,
      'area': area,
      'type': type,
      'financial_range': financialRange,
      'source_id': sourceId,
      'sale_id': saleId,
      'status': status,
      'keyword': keyword,
      'created_at': createdAt,
      'customer_type': customerType,
      'page': '$page',
      'per_page': '$perPage',
    };
  }

  KhachHangFilter copyWith({
    List<int>? projectId,
    List<String>? area,
    List<String>? type,
    List<String>? financialRange,
    List<int>? sourceId,
    List<int>? saleId,
    List<int>? status,
    String? keyword,
    String? createdAt,
    String? customerType,
    int? page,
    int? perPage,
  }) {
    return KhachHangFilter(
      projectId: projectId ?? this.projectId,
      area: area ?? this.area,
      type: type ?? this.type,
      financialRange: financialRange ?? this.financialRange,
      sourceId: sourceId ?? this.sourceId,
      saleId: saleId ?? this.saleId,
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      createdAt: createdAt ?? this.createdAt,
      customerType: customerType ?? this.customerType,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  List<Object?> get props => [
    projectId,
    area,
    type,
    financialRange,
    sourceId,
    saleId,
    status,
    keyword,
    createdAt,
    customerType,
    page,
    perPage,
  ];
}
