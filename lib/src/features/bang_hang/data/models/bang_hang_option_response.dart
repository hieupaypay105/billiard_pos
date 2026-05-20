/// Response model for `/data/option` endpoint.
///
/// The `filter` field is dynamic — its keys change based on the `type`
/// query parameter (e.g. 'area', 'type', 'direction', 'handover_status').
/// We expose the values as a flat [List<String>] for use in dropdowns.
class BangHangOptionResponse {
  const BangHangOptionResponse({required this.options});

  factory BangHangOptionResponse.fromJson(Map<String, dynamic> json) {
    // API returns 'fliter' (typo), fallback to 'filter'.
    final filter = json['fliter'] ?? json['filter'];
    if (filter is! Map<String, dynamic>) {
      return const BangHangOptionResponse(options: []);
    }

    // Use values (display labels) as option strings.
    final options = filter.values.whereType<String>().toList();
    return BangHangOptionResponse(options: options);
  }

  /// Display labels extracted from the `filter` map values.
  final List<String> options;
}
