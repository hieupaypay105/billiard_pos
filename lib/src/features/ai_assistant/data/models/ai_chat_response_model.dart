import 'package:anholding_app/src/features/ai_assistant/data/models/ai_quota_info_model.dart';
import 'package:anholding_app/src/features/ai_assistant/data/models/ai_quota_request_info_model.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_chat_response.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_item_model.dart';

class AiChatResponseModel extends AiChatResponse {
  const AiChatResponseModel({
    super.filters,
    super.reply,
    super.quotaInfo,
    super.quotaRequestInfo,
    super.items,
  });

  factory AiChatResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse items mapping safe to BangHangModel
    List<dynamic>? parsedItems;
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => BangHangItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AiChatResponseModel(
      filters: json['filters'] as Map<String, dynamic>?,
      reply: json['reply'] as String?,
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
      if (reply != null) 'reply': reply,
      if (quotaInfo != null)
        'quota_info': (quotaInfo! as AiQuotaInfoModel).toJson(),
      if (quotaRequestInfo != null)
        'quota_request_info': (quotaRequestInfo! as AiQuotaRequestInfoModel)
            .toJson(),
      // In CRM we rarely serialize the response back to JSON exactly like API, but we provide it here
      if (items != null)
        'items': items!.map((e) => (e as BangHangItemModel).toJson()).toList(),
    };
  }
}
