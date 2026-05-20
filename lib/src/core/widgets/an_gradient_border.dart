import 'dart:math' as math;

import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A reusable widget that wraps its child with the standard AnHolding gradient border.
///
/// Use this anywhere you need the glowing border effect (Containers, Buttons, Cards).
class AnGradientBorder extends StatelessWidget {
  const AnGradientBorder({
    required this.child,
    super.key,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.borderWidth = 1.0,
    this.borderRadius = 8.0, // Default padding from card features
    this.backgroundColor = AppColors.filterBg,
    this.gradientRotationDegrees = 0.0,
  });

  /// The widget that you want to wrap with the gradient border.
  final Widget child;

  /// The width of the outer gradient border container. Can be null.
  final double? width;

  /// The height of the outer gradient border container. Can be null.
  final double? height;

  /// The inner padding applied to the child content. Defaults to 0 since padding can be applied to the child itself.
  final EdgeInsetsGeometry padding;

  /// The width/thickness of the gradient border. Defaults to 1.0.
  final double borderWidth;

  /// The border radius for the corners. Defaults to 4.0.
  final double borderRadius;

  /// The internal background color behind the child. Defaults to [AppColors.filterBg].
  final Color backgroundColor;

  /// The rotation of the gradient border in degrees. Defaults to 0.
  final double gradientRotationDegrees;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          stops: const [0.0, 0.49, 1.0],
          colors: const [
            AppColors.titleGradientStart, // #FFDBB0
            AppColors.titleGradientMiddle, // #9C531B
            AppColors.titleGradientStart, // #FFDBB0
          ],
          transform: GradientRotation(gradientRotationDegrees * math.pi / 180),
        ),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            (borderRadius - borderWidth).clamp(0, double.infinity),
          ),
        ),
        // Alignment not forced, allows child to determine size or behavior
        child: child,
      ),
    );
  }
}
