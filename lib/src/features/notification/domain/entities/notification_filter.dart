import 'package:equatable/equatable.dart';

class NotificationFilter extends Equatable {
  const NotificationFilter({
    this.type = 'CUSTOMER',
  });

  final String? type;

  NotificationFilter copyWith({
    String? type,
  }) {
    return NotificationFilter(
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (type != null && type!.isNotEmpty) {
      params['notification_type'] = type;
    }
    return params;
  }

  @override
  List<Object?> get props => [type];
}
