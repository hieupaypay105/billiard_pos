import 'dart:ui';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthGlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry margin;

  const AuthGlassCard({
    super.key,
    required this.child,
    this.height,
    this.margin = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            height: height,
            decoration: const BoxDecoration(
              color: AppColors.authCardBackground,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
