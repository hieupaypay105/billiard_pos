class CongTacVienOptionResponse {
  const CongTacVienOptionResponse({
    required this.status,
    required this.sale,
    required this.attribute,
  });

  factory CongTacVienOptionResponse.fromJson(Map<String, dynamic> json) {
    return CongTacVienOptionResponse(
      status: _parseStringList(json['status']),
      sale: _parseIdLabelMap(json['sale']),
      attribute: _parseStringMap(json['atrtibute'] ?? json['attribute']),
    );
  }

  final List<String> status;
  final Map<int, String> sale;
  final Map<String, String> attribute;

  static List<String> _parseStringList(value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static Map<int, String> _parseIdLabelMap(value) {
    if (value is! Map) return const {};

    final result = <int, String>{};
    value.forEach((key, item) {
      if (item is Map) {
        final id = int.tryParse(item['id']?.toString() ?? key.toString());
        final label = item['label']?.toString();
        if (id == null || label == null || label.isEmpty) return;
        result[id] = label;
        return;
      }

      final id = int.tryParse(key.toString());
      if (id == null) return;
      result[id] = item.toString();
    });
    return result;
  }

  static Map<String, String> _parseStringMap(value) {
    if (value is! Map) return const {};

    final result = <String, String>{};
    value.forEach((key, item) {
      result[key.toString()] = item.toString();
    });
    return result;
  }
}
