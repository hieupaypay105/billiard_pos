import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthBottomCard extends StatelessWidget {
  const AuthBottomCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundSolid,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}
