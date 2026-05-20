import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Gold pill-shaped button used across the auth flow.
///
/// Set [isOutlined] to `true` for the "Quay lại" (Back) variant
/// which shows a gold border instead of a filled background.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  /// Optional fixed width. Defaults to expand to parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : null,
          gradient: isOutlined
              ? null
              : const LinearGradient(
                  colors: [
                    AppColors.buttonGradientStart,
                    AppColors.buttonGradientEnd,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOutlined ? AppColors.textDark : AppColors.buttonBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textDark,
                      ),
                    )
                  : Text(
                      text,
                      style: AppTextStyles.buttonLabel.copyWith(
                        color: isOutlined
                            ? AppColors.textDark
                            : AppColors.buttonText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
