import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';

class AiQuotaRequestInfoModel extends AiQuotaRequestInfo {
  const AiQuotaRequestInfoModel({
    required super.used,
    required super.quota,
    required super.cost,
    required super.percent,
    required super.monthRequests,
  });

  factory AiQuotaRequestInfoModel.fromJson(Map<String, dynamic> json) {
    return AiQuotaRequestInfoModel(
      used: json['used']?.toString() ?? '0',
      quota: json['quota'] is int
          ? json['quota'] as int
          : int.tryParse(json['quota']?.toString() ?? '0') ?? 0,
      cost: json['cost'] is int
          ? json['cost'] as int
          : int.tryParse(json['cost']?.toString() ?? '0') ?? 0,
      percent: json['percent'] is double
          ? json['percent'] as double
          : double.tryParse(json['percent']?.toString() ?? '0.0') ?? 0.0,
      monthRequests: json['month_requests']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
        'used': used,
        'quota': quota,
        'cost': cost,
        'percent': percent,
        'month_requests': monthRequests,
      };
}
