import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import '../../core/constants/app_colors.dart';

class TableCard extends StatefulWidget {
  final TableModel table;
  final Duration duration;
  final double cost;
  final bool isSelected;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.duration,
    required this.cost,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.table.status == 'active';
    
    // Modern HSL Tailored Color Palette (Scandinavian Minimalism)
    Color cardBg;
    Color accentBorderColor;
    Color statusDotColor;
    String statusText;

    if (isActive) {
      cardBg = const Color(0xFFF5F2F0); // Warm grey surface
      accentBorderColor = AppColors.primary;
      statusDotColor = const Color(0xFF0D9488); // Teal Green
      statusText = 'Đang chơi';
    } else if (widget.table.status == 'maintenance') {
      cardBg = const Color(0xFFFEF2F2); // Soft Light Red
      accentBorderColor = const Color(0xFFEF4444);
      statusDotColor = const Color(0xFFEF4444);
      statusText = 'Bảo trì';
    } else {
      cardBg = Colors.white;
      accentBorderColor = Colors.grey[200]!;
      statusDotColor = Colors.grey[400]!;
      statusText = 'Bàn trống';
    }

    // Highlight border when selected
    if (widget.isSelected) {
      accentBorderColor = AppColors.primary;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: _isHovered 
              ? (Matrix4.identity()..translate(0, -4, 0)) 
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentBorderColor,
              width: widget.isSelected ? 2.5 : (_isHovered ? 1.5 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isSelected 
                    ? 0.12 
                    : (_isHovered ? 0.08 : 0.03)),
                blurRadius: widget.isSelected ? 16 : (_isHovered ? 12 : 6),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Name + Status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.table.tableName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF212121),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusDotColor,
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: statusDotColor.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          )
                        ] : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Table Type tag
                Text(
                  widget.table.tableTypeId == 1
                      ? 'Bàn Pool (Bàn lỗ)'
                      : widget.table.tableTypeId == 2
                          ? 'Bàn Carom (Bàn phăng)'
                          : 'Bàn Snooker',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const Spacer(),
                
                // Content depending on state
                if (isActive) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thời gian:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDuration(widget.duration),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          fontFamily: 'Courier',
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tạm tính:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatCurrency(widget.cost),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: widget.table.status == 'maintenance' 
                            ? Colors.red[700] 
                            : Colors.grey[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
