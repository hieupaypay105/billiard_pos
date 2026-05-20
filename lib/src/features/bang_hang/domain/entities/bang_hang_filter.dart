/// Domain filter entity for Bang Hang (Sales Board) feature.
library;

const Object _kBangHangFilterUnset = Object();

class BangHangTab {
  const BangHangTab({
    required this.id,
    required this.label,
    required this.projectId,
  });

  final String id;
  final String label;
  final int projectId;
}

class RangeFilter {
  const RangeFilter({this.min, this.max});

  final double? min;
  final double? max;

  bool get isEmpty => min == null && max == null;

  Map<String, dynamic> toJson() {
    return {
      if (min != null) 'min': min!.toInt(),
      if (max != null) 'max': max!.toInt(),
    };
  }

  RangeFilter copyWith({double? min, double? max}) {
    return RangeFilter(min: min ?? this.min, max: max ?? this.max);
  }
}

class BangHangFilter {
  const BangHangFilter({
    this.projectId = 2,
    this.area = const [],
    this.type = const [],
    this.telesale = const [],
    this.direction = const [],
    this.handoverStatus = const [],
    this.code,
    this.price = const RangeFilter(),
    this.tts = const RangeFilter(),
    this.acreage = const RangeFilter(),
    this.page = 1,
    this.perPage = 50,
  });

  final int projectId;
  final List<String> area;
  final List<String> type;
  final List<String> telesale;
  final List<String> direction;
  final List<String> handoverStatus;

  /// Search by property code (Mã căn).
  final String? code;

  final RangeFilter price;
  final RangeFilter tts;
  final RangeFilter acreage;
  final int page;
  final int perPage;

  Map<String, dynamic> toPayload() {
    return {
      'project_id': projectId,
      'area': area,
      'type': type,
      'telesale': telesale,
      'direction': direction,
      'handover_status': handoverStatus,
      if (code != null && code!.isNotEmpty) 'code': code,
      if (!price.isEmpty) 'price': price.toJson(),
      if (!tts.isEmpty) 'tts': tts.toJson(),
      if (!acreage.isEmpty) 'acreage': acreage.toJson(),
      'page': '$page',
      'per_page': '$perPage',
    };
  }

  BangHangFilter copyWith({
    int? projectId,
    List<String>? area,
    List<String>? type,
    List<String>? telesale,
    List<String>? direction,
    List<String>? handoverStatus,
    Object? code = _kBangHangFilterUnset,
    RangeFilter? price,
    RangeFilter? tts,
    RangeFilter? acreage,
    int? page,
    int? perPage,
  }) {
    return BangHangFilter(
      projectId: projectId ?? this.projectId,
      area: area ?? this.area,
      type: type ?? this.type,
      telesale: telesale ?? this.telesale,
      direction: direction ?? this.direction,
      handoverStatus: handoverStatus ?? this.handoverStatus,
      code: identical(code, _kBangHangFilterUnset)
          ? this.code
          : code as String?,
      price: price ?? this.price,
      tts: tts ?? this.tts,
      acreage: acreage ?? this.acreage,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}
