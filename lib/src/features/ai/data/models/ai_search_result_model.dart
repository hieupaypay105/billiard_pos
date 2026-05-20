import 'package:anholding_app/src/features/ai/domain/entities/ai_search_result.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_item_model.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';

class AiQuotaInfoModel extends AiQuotaInfo {
  const AiQuotaInfoModel({
    required super.used,
    required super.quota,
    required super.cost,
    required super.percent,
    super.monthRequests,
  });

  factory AiQuotaInfoModel.fromJson(Map<String, dynamic> json) {
    return AiQuotaInfoModel(
      used: json['used']?.toString() ?? '0',
      quota: int.tryParse(json['quota']?.toString() ?? '') ?? 0,
      cost: num.tryParse(json['cost']?.toString() ?? '') ?? 0,
      percent: num.tryParse(json['percent']?.toString() ?? '') ?? 0,
      monthRequests: json['month_requests']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used': used,
      'quota': quota,
      'cost': cost,
      'percent': percent,
      'month_requests': monthRequests,
    };
  }
}

class AiSearchResultModel extends AiSearchResult {
  const AiSearchResultModel({
    required super.filters,
    super.quotaInfo,
    super.quotaRequestInfo,
    required super.items,
  });

  factory AiSearchResultModel.fromJson(Map<String, dynamic> json) {
    final Set<String> _bangHangFields = {'acreage', 'project_name', 'construction_area'};
    List<BangHangItem> parsedItems = [];
    
    if (json['items'] is List) {
      final list = json['items'] as List;
      if (list.isNotEmpty) {
        final firstItem = list.first as Map<String, dynamic>;
        
        bool isBangHang = false;
        for (final field in _bangHangFields) {
          if (firstItem.containsKey(field)) {
            isBangHang = true;
            break;
          }
        }
        
        if (isBangHang) {
           parsedItems = list.map((e) => BangHangItemModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    }

    return AiSearchResultModel(
      filters: json['filters'] != null ? Map<String, dynamic>.from(json['filters'] as Map) : {},
      quotaInfo: json['quota_info'] != null ? AiQuotaInfoModel.fromJson(json['quota_info'] as Map<String, dynamic>) : null,
      quotaRequestInfo: json['quota_request_info'] != null ? AiQuotaInfoModel.fromJson(json['quota_request_info'] as Map<String, dynamic>) : null,
      items: parsedItems,
    );
  }
}
