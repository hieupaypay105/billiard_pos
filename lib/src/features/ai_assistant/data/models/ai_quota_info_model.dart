import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_info.dart';

class AiQuotaInfoModel extends AiQuotaInfo {
  const AiQuotaInfoModel({
    required super.used,
    required super.quota,
    required super.cost,
    required super.percent,
  });

  factory AiQuotaInfoModel.fromJson(Map<String, dynamic> json) {
    return AiQuotaInfoModel(
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
    );
  }

  Map<String, dynamic> toJson() => {
        'used': used,
        'quota': quota,
        'cost': cost,
        'percent': percent,
      };
}
