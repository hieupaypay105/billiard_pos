import 'dart:ui';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({
    required this.currentIndex,
    required this.onTabChanged,
    super.key,
  });

  static const double _barContentHeight = 80;

  static const List<_BottomNavItemData> _items = [
    _BottomNavItemData(
      index: 0,
      iconPath: AppIcons.homeNav,
      label: 'HOME',
    ),
    _BottomNavItemData(
      index: 1,
      iconPath: AppIcons.bangHangNav,
      label: 'BẢNG HÀNG',
    ),
    _BottomNavItemData(
      index: 2,
      iconPath: AppIcons.ctvNav,
      label: 'CTV',
    ),
    _BottomNavItemData(
      index: 3,
      iconPath: AppIcons.khachHangNav,
      label: 'KHÁCH HÀNG',
    ),
    _BottomNavItemData(
      index: 4,
      iconPath: AppIcons.aiAssistant,
      label: 'TRỢ LÝ AI',
    ),
  ];

  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: _barContentHeight + safeBottom,
          decoration: const BoxDecoration(
            color: AppColors.topBarBlurBackground,
            boxShadow: [
              BoxShadow(
                color: Color(
                  0x0F37312E,
                ), // rgba(55,49,46,0.06) => 0.06 is ~0x0F
                offset: Offset(0, -40),
                blurRadius: 40,
                spreadRadius: -15,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 1,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFDBB0),
                      Color(0xFF9C531B),
                      Color(0xFFFFDBB0),
                    ],
                    stops: [0.0885, 0.5097, 0.9559],
                  ),
                ),
              ),
              SizedBox(
                height: _barContentHeight - 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final item in _items)
                      _BottomNavItem(
                        iconPath: item.iconPath,
                        label: item.label,
                        isActive: currentIndex == item.index,
                        onTap: () => onTabChanged(item.index),
                      ),
                  ],
                ),
              ),
              SizedBox(height: safeBottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({
    required this.index,
    required this.iconPath,
    required this.label,
  });

  final int index;
  final String iconPath;
  final String label;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.iconPath,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: isActive ? 1.0 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.authButtonText,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.authButtonText,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(height: 7), // reserve space for indicator
            ],
          ),
        ),
      ),
    );
  }
}
