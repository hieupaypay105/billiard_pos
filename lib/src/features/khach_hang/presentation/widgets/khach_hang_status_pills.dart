import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:flutter/material.dart';

class KhachHangStatusPills extends StatelessWidget {
  const KhachHangStatusPills({
    required this.options,
    this.selectedStatuses = const [],
    this.statusCounts = const {},
    this.onStatusTap,
    super.key,
  });

  final KhachHangOptionResponse options;
  final List<int> selectedStatuses;

  /// Status index → count, e.g. {0: 338, 1: 554, ...}
  final Map<int, int> statusCounts;
  final ValueChanged<int>? onStatusTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: options.status.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (_, index) {
          final isSelected =
              selectedStatuses.isEmpty || selectedStatuses.contains(index);
          final opacity = isSelected ? 1.0 : 0.15;

          final baseColor = index < AppColors.khStatusColors.length
              ? AppColors.khStatusColors[index]
              : Colors.grey;
          final color = baseColor.withValues(alpha: opacity);

          final count = statusCounts[index];
          final hasCount = count != null && count > 0;
          final label = options.status[index];
          final displayText = hasCount
              ? '$label (${count > 999 ? '999+' : count})'
              : label;

          return GestureDetector(
            onTap: onStatusTap != null ? () => onStatusTap!(index) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayText.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.45,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
