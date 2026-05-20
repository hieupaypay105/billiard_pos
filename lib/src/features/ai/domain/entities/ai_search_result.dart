import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:equatable/equatable.dart';

class AiQuotaInfo extends Equatable {
  final String used;
  final int quota;
  final num cost;
  final num percent;
  final String? monthRequests;

  const AiQuotaInfo({
    required this.used,
    required this.quota,
    required this.cost,
    required this.percent,
    this.monthRequests,
  });

  @override
  List<Object?> get props => [used, quota, cost, percent, monthRequests];
}

class AiSearchResult extends Equatable {
  final Map<String, dynamic> filters;
  final AiQuotaInfo? quotaInfo;
  final AiQuotaInfo? quotaRequestInfo;
  final List<BangHangItem> items;

  const AiSearchResult({
    required this.filters,
    this.quotaInfo,
    this.quotaRequestInfo,
    required this.items,
  });

  @override
  List<Object?> get props => [filters, quotaInfo, quotaRequestInfo, items];

  AiSearchResult copyWith({
    Map<String, dynamic>? filters,
    AiQuotaInfo? quotaInfo,
    AiQuotaInfo? quotaRequestInfo,
    List<BangHangItem>? items,
  }) {
    return AiSearchResult(
      filters: filters ?? this.filters,
      quotaInfo: quotaInfo ?? this.quotaInfo,
      quotaRequestInfo: quotaRequestInfo ?? this.quotaRequestInfo,
      items: items ?? this.items,
    );
  }
}
