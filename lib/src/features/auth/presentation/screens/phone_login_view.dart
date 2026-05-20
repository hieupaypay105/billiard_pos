import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_action_button.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_background_widget.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Screen 1 — Enter phone number to request OTP.
class PhoneLoginView extends StatefulWidget {
  const PhoneLoginView({super.key});

  @override
  State<PhoneLoginView> createState() => _PhoneLoginViewState();
}

class _PhoneLoginViewState extends State<PhoneLoginView> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _onContinue(BuildContext context, AuthViewModel vm) async {
    _formKey.currentState?.save();
    var phone = _formKey.currentState?.value['phone'] as String? ?? '';
    phone = phone.trim();

    // Auto prepend 0 if length is 9
    if (phone.length == 9 && !phone.startsWith('0')) {
      phone = '0$phone';
    }

    vm.phoneNumber = phone;
    final success = await vm.submitPhone();
    if (success && context.mounted) {
      await context.push<void>('/otp-verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AuthBackgroundWidget(
      child: Stack(
        children: [
          // ── Logo ─────────────────────────────────────────
          Positioned(
            top: 40, // Increased safe area margin instead of absolute 121
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: isKeyboardVisible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: isKeyboardVisible ? 0 : 1,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 203,
                    height: 72,
                  ),
                ),
              ),
            ),
          ),

          // ── Center Card ──────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: AuthGlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome Header
                        Text(
                          'CHÀO MỪNG',
                          style: AppTextStyles.authScreenTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2.7,
                            color: AppColors.authTextLight,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng nhập số điện thoại để tiếp tục',
                          style: AppTextStyles.bodyWhite.copyWith(
                            color: AppColors.authTextMuted,
                          ),
                          textAlign: TextAlign.left,
                        ),

                        const SizedBox(height: 48),

                        // Input Label
                        Text(
                          'NHẬP SỐ ĐIỆN THOẠI',
                          style: AppTextStyles.authLabel,
                        ),
                        const SizedBox(height: 12),

                        // Phone input
                        FormBuilderTextField(
                          name: 'phone',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: AppTextStyles.inputValue.copyWith(
                            color: AppColors.authTextLight,
                          ),
                          decoration: InputDecoration(
                            prefixIconConstraints: const BoxConstraints(),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                '+84',
                                style: AppTextStyles.inputValue.copyWith(
                                  color: AppColors.authTextLight,
                                ),
                              ),
                            ),
                            hintText: '000 000 000',
                            hintStyle: AppTextStyles.inputHint.copyWith(
                              color: AppColors.authTextMuted,
                              fontSize: 16,
                            ),
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(
                              top: 8,
                              bottom: 9,
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.authInputBorder,
                              ),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.authInputBorder,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.authTextSecondary,
                              ),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                          ),
                        ),

                        // Error message
                        if (vm.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            vm.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],

                        const SizedBox(height: 64),

                        // Continue button
                        AuthActionButton(
                          text: 'TIẾP TỤC',
                          isLoading: vm.isLoading,
                          onPressed: () => _onContinue(context, vm),
                        ),

                        const SizedBox(height: 48),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Support action placeholder
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'HỖ TRỢ KỸ THUẬT',
                              style: AppTextStyles.authHelpLink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: isKeyboardVisible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: isKeyboardVisible ? 0 : 1,
                child: Center(
                  child: Text(
                    '© 2026 AN HOLDINGS GROUP. ALL RIGHTS RESERVED.',
                    style: AppTextStyles.authFooter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
