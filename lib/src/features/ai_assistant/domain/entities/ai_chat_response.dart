import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_info.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:equatable/equatable.dart';

class AiChatResponse extends Equatable {
  const AiChatResponse({
    this.filters,
    this.reply,
    this.quotaInfo,
    this.quotaRequestInfo,
    this.items,
  });
  final Map<String, dynamic>? filters;
  final String? reply;
  final AiQuotaInfo? quotaInfo;
  final AiQuotaRequestInfo? quotaRequestInfo;
  final List<dynamic>? items;

  @override
  List<Object?> get props => [
    filters,
    reply,
    quotaInfo,
    quotaRequestInfo,
    items,
  ];
}
