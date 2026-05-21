import 'dart:convert';
import 'package:equatable/equatable.dart';

class TablePriceModel extends Equatable {
  final int id;
  final int tableTypeId;
  final double pricePerHour;
  final String startHour; // format: 'HH:mm:ss'
  final String endHour; // format: 'HH:mm:ss'
  final List<int>? daysOfWeek; // days of week, e.g. [1, 2, 3, 4, 5] (Monday-Friday)
  final bool isActive;
  final int priority;

  const TablePriceModel({
    required this.id,
    required this.tableTypeId,
    required this.pricePerHour,
    this.startHour = '00:00:00',
    this.endHour = '23:59:59',
    this.daysOfWeek,
    this.isActive = true,
    this.priority = 0,
  });

  factory TablePriceModel.fromJson(Map<String, dynamic> json) {
    List<int>? parsedDays;
    if (json['days_of_week'] != null) {
      if (json['days_of_week'] is List) {
        parsedDays = (json['days_of_week'] as List).map((e) => e as int).toList();
      } else if (json['days_of_week'] is String) {
        try {
          final decoded = jsonDecode(json['days_of_week'] as String);
          if (decoded is List) {
            parsedDays = decoded.map((e) => e as int).toList();
          }
        } catch (_) {}
      }
    }

    return TablePriceModel(
      id: json['id'] as int,
      tableTypeId: json['table_type_id'] as int,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      startHour: json['start_hour'] as String? ?? '00:00:00',
      endHour: json['end_hour'] as String? ?? '23:59:59',
      daysOfWeek: parsedDays,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : (json['is_active'] == 1 || json['is_active'] == 'true'),
      priority: json['priority'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_type_id': tableTypeId,
      'price_per_hour': pricePerHour,
      'start_hour': startHour,
      'end_hour': endHour,
      'days_of_week': daysOfWeek,
      'is_active': isActive,
      'priority': priority,
    };
  }

  @override
  List<Object?> get props => [
        id,
        tableTypeId,
        pricePerHour,
        startHour,
        endHour,
        daysOfWeek,
        isActive,
        priority,
      ];
}
