import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AuthOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double height;
  final double? width;

  const AuthOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.authTextDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          side: const BorderSide(
            color: AppColors.authOutlinedButtonBorder,
            width: 1,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: AppTextStyles.authButtonLabel.copyWith(
            color: AppColors.authTextDisabled,
          ),
        ),
      ),
    );
  }
}
