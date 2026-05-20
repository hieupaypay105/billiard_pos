import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_background_widget.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_glass_card.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/otp_pin_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Screen 5 — Returning user logs in with their PIN.
///
/// Entry point for cached sessions. Shows user avatar, name, phone,
/// a switch-account action, PIN input, forgot-PIN link, and login button.
class PinLoginView extends StatefulWidget {
  const PinLoginView({super.key});

  @override
  State<PinLoginView> createState() => _PinLoginViewState();
}

class _PinLoginViewState extends State<PinLoginView> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    // Load saved user info (phone, name) from secure storage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<AuthViewModel>().loadSavedUser());
    });
  }

  Future<void> _onLogin(BuildContext context, AuthViewModel vm) async {
    _formKey.currentState?.save();
    final pin = _formKey.currentState?.value['pin'] as String? ?? '';
    final success = await vm.loginWithPin(pin);
    if (success && context.mounted) {
      context.go(RoutePaths.dashboard);
    }
  }

  Future<void> _onSwitchAccount(
    BuildContext context,
    AuthViewModel vm,
  ) async {
    // Clear all saved PIN + user info, then navigate to phone login.
    await vm.pinStorage.clearAll();
    vm.reset();
    if (context.mounted) {
      context.go(RoutePaths.phoneLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = context.watch<UserProvider>().currentUser;
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AuthBackgroundWidget(
      child: Stack(
        children: [
          // ── Logo ─────────────────────────────────────────
          Positioned(
            top: 40,
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
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CHÀO MỪNG',
                              style: AppTextStyles.authScreenTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2.7,
                                color: AppColors.authTextDisabled,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            // Switch Account Link
                            InkWell(
                              onTap: () => _onSwitchAccount(context, vm),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.refresh_rounded,
                                    color: AppColors.authTextSecondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đổi tài khoản',
                                    style: AppTextStyles.smallWhite.copyWith(
                                      color: AppColors.authTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // User Name with gradient shader
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFDBB0),
                              Color(0xFF9C531B),
                              Color(0xFFFFDBB0),
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            user?.fullname ?? '',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Colors.white, // Required for shader
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Instruction
                        Text(
                          'Vui lòng nhập mã PIN để sử dụng',
                          style: AppTextStyles.bodyWhite.copyWith(
                            color: AppColors.authTextLight,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 17),

                        // PIN input
                        FormBuilderField<String>(
                          name: 'pin',
                          builder: (field) {
                            return Column(
                              children: [
                                OtpPinInputWidget(
                                  obscureText: true,
                                  autoFocus: true,
                                  boxSize: 35,
                                  onCompleted: (value) async {
                                    field.didChange(value);
                                    if (context.mounted) {
                                      await _onLogin(context, vm);
                                    }
                                  },
                                  onChanged: (value) => field.didChange(value),
                                ),
                                if (field.hasError) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    field.errorText ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // API Error (e.g. "Mã PIN không đúng")
                        if (vm.errorMessage != null) ...[
                          Text(
                            vm.errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Forgot PIN ───────────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              final result = await vm.startForgotPin();
                              if (!context.mounted) return;
                              if (result == ForgotPinStartResult.started) {
                                await context.push<void>(
                                  RoutePaths.otpVerification,
                                );
                              } else if (result ==
                                  ForgotPinStartResult.missingPhone) {
                                context.go(RoutePaths.phoneLogin);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Quên mã PIN ?',
                              style: AppTextStyles.bodyWhite.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // const SizedBox(height: 16),

                        // // Continue button
                        // AuthActionButton(
                        //   text: 'ĐĂNG NHẬP',
                        //   isLoading: vm.isLoading,
                        //   onPressed: () => _onLogin(context, vm),
                        // ),
                        const SizedBox(height: 31),

                        // Support Help Link
                        Center(
                          child: TextButton(
                            onPressed: () {},
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
