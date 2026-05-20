import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_info.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_item.dart';
import 'package:equatable/equatable.dart';

class AiTableSearchResult extends Equatable {
  const AiTableSearchResult({
    this.filters,
    this.quotaInfo,
    this.quotaRequestInfo,
    required this.items,
  });

  final Map<String, dynamic>? filters;
  final AiQuotaInfo? quotaInfo;
  final AiQuotaRequestInfo? quotaRequestInfo;
  final List<BangHangItem> items;

  @override
  List<Object?> get props => [
        filters,
        quotaInfo,
        quotaRequestInfo,
        items,
      ];
}
