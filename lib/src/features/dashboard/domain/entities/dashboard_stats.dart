import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.totalRevenue,
    required this.activeUsers,
    required this.newOrders,
    required this.monthlySales,
  });

  final double totalRevenue;
  final int activeUsers;
  final int newOrders;
  final List<double> monthlySales;

  @override
  List<Object?> get props => [
    totalRevenue,
    activeUsers,
    newOrders,
    monthlySales,
  ];
}
