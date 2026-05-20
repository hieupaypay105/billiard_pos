import 'package:anholding_app/src/features/ai_assistant/data/models/ai_quota_info_model.dart';
import 'package:anholding_app/src/features/ai_assistant/data/models/ai_quota_request_info_model.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_table_search_result.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_item_model.dart';

class AiTableSearchResultModel extends AiTableSearchResult {
  const AiTableSearchResultModel({
    required super.items,
    super.filters,
    super.quotaInfo,
    super.quotaRequestInfo,
  });

  factory AiTableSearchResultModel.fromJson(Map<String, dynamic> json) {
    var parsedItems = <BangHangItemModel>[];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => BangHangItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AiTableSearchResultModel(
      filters: json['filters'] as Map<String, dynamic>?,
      quotaInfo: json['quota_info'] != null
          ? AiQuotaInfoModel.fromJson(
              json['quota_info'] as Map<String, dynamic>,
            )
          : null,
      quotaRequestInfo: json['quota_request_info'] != null
          ? AiQuotaRequestInfoModel.fromJson(
              json['quota_request_info'] as Map<String, dynamic>,
            )
          : null,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (filters != null) 'filters': filters,
      if (quotaInfo != null)
        'quota_info': (quotaInfo! as AiQuotaInfoModel).toJson(),
      if (quotaRequestInfo != null)
        'quota_request_info': (quotaRequestInfo! as AiQuotaRequestInfoModel)
            .toJson(),
      'items': items.map((e) => (e as BangHangItemModel).toJson()).toList(),
    };
  }
}
