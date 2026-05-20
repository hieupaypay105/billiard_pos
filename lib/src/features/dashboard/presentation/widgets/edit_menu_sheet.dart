import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/dashboard/data/models/menu_item.dart';
import 'package:anholding_app/src/features/dashboard/presentation/provider/menu_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

/// Bottom sheet cho phép chỉnh sửa danh sách menu hiển thị trên Dashboard.
///
/// Hiển thị tất cả các mục trong allMenuItems (mảng A).
/// - Mục đã có trong B → badge trừ đỏ (tap để xoá)
/// - Mục chưa có trong B → badge cộng xanh (tap để thêm)
/// - Nút "Lưu" để lưu thay đổi
class EditMenuSheet extends StatelessWidget {
  const EditMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.cardBackgroundSolid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Menu grid
              _buildMenuGrid(menuProvider),

              const SizedBox(height: 24),

              // Nút Lưu
              SizedBox(
                width: 161,
                height: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.buttonGradientStart,
                        AppColors.buttonGradientEnd,
                      ],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        await menuProvider.saveEditing();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Center(
                        child: Text(
                          'Lưu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.buttonText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid(MenuProvider menuProvider) {
    const items = allMenuItems;
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i += 3) {
      final rowItems = items.sublist(
        i,
        (i + 3) > items.length ? items.length : i + 3,
      );

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...rowItems.map((item) {
              final isActive = menuProvider.isInEditing(item.id);
              return _EditableMenuButton(
                item: item,
                isActive: isActive,
                onTap: () {
                  if (isActive) {
                    menuProvider.removeFromEditing(item.id);
                  } else {
                    menuProvider.addToEditing(item.id);
                  }
                },
              );
            }),
            // Pad nếu hàng chưa đủ 3 cột
            ...List.generate(
              3 - rowItems.length,
              (_) => const SizedBox(width: 80),
            ),
          ],
        ),
      );

      if (i + 3 < items.length) {
        rows.add(const SizedBox(height: 24));
      }
    }

    return Column(children: rows);
  }
}

class _EditableMenuButton extends StatelessWidget {
  const _EditableMenuButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final MenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48392A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      item.iconPath,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                // Badge trừ (đỏ) hoặc cộng (xanh)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isActive ? Icons.remove : Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
