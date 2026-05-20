class KhachHangOptionResponse {
  const KhachHangOptionResponse({
    required this.status,
    required this.source,
    required this.project,
    required this.sale,
    required this.attribute,
    required this.financialRange,
    required this.createdAt,
    required this.filterSaved,
    required this.region,
  });

  factory KhachHangOptionResponse.fromJson(Map<String, dynamic> json) {
    return KhachHangOptionResponse(
      status: _parseStringList(json['status']),
      source: _parseIdLabelMap(json['source']),
      project: _parseIdLabelMap(json['project']),
      sale: _parseIdLabelMap(json['sale']),
      attribute: _parseStringMap(json['atrtibute'] ?? json['attribute']),
      financialRange: _parseStringMap(json['financial_range']),
      createdAt: _parseStringMap(json['created_at']),
      filterSaved: _parseFilterSavedList(json['filter_saved']),
      region: _parseIdLabelMap(json['region']),
    );
  }

  final List<String> status;
  final Map<int, String> source;
  final Map<int, String> project;
  final Map<int, String> sale;
  final Map<String, String> attribute;
  final Map<String, String> financialRange;
  final Map<String, String> createdAt;
  final List<KhachHangFilterSaved> filterSaved;
  final Map<int, String> region;

  static List<String> _parseStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static Map<int, String> _parseIdLabelMap(Object? value) {
    if (value is! Map) return const {};

    final result = <int, String>{};
    value.forEach((key, item) {
      final id = int.tryParse(key.toString());
      if (id == null) return;
      result[id] = item.toString();
    });
    return result;
  }

  static Map<String, String> _parseStringMap(Object? value) {
    if (value is! Map) return const {};

    final result = <String, String>{};
    value.forEach((key, item) {
      result[key.toString()] = item.toString();
    });
    return result;
  }

  static List<KhachHangFilterSaved> _parseFilterSavedList(Object? value) {
    if (value is! List) return const [];

    final result = <KhachHangFilterSaved>[];
    for (final item in value) {
      if (item is Map) {
        result.add(
          KhachHangFilterSaved.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return result;
  }
}

class KhachHangFilterSaved {
  const KhachHangFilterSaved({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.data,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory KhachHangFilterSaved.fromJson(Map<String, dynamic> json) {
    return KhachHangFilterSaved(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      isDefault: json['is_default']?.toString() ?? '0',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String type;
  final String data;
  final String isDefault;
  final String? createdAt;
  final String? updatedAt;
}
