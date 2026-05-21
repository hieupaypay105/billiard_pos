import 'package:equatable/equatable.dart';

class IotConfigModel extends Equatable {
  final int id;
  final String tableId;
  final String connectionType; // 'serial', 'tcp_ip'
  final String? ipAddress;
  final String? port; // COM port like 'COM3' or TCP port like '8080'
  final int relayChannel;
  final String commandOn; // Hex command to turn ON, e.g. '01050000FF008C3A'
  final String commandOff; // Hex command to turn OFF, e.g. '010500000000CDCA'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IotConfigModel({
    required this.id,
    required this.tableId,
    required this.connectionType,
    this.ipAddress,
    this.port,
    required this.relayChannel,
    required this.commandOn,
    required this.commandOff,
    this.createdAt,
    this.updatedAt,
  });

  factory IotConfigModel.fromJson(Map<String, dynamic> json) {
    return IotConfigModel(
      id: json['id'] as int,
      tableId: json['table_id'] as String,
      connectionType: json['connection_type'] as String,
      ipAddress: json['ip_address'] as String?,
      port: json['port']?.toString(),
      relayChannel: json['relay_channel'] as int,
      commandOn: json['command_on'] as String,
      commandOff: json['command_off'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'connection_type': connectionType,
      'ip_address': ipAddress,
      'port': port,
      'relay_channel': relayChannel,
      'command_on': commandOn,
      'command_off': commandOff,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        tableId,
        connectionType,
        ipAddress,
        port,
        relayChannel,
        commandOn,
        commandOff,
        createdAt,
        updatedAt,
      ];
}
