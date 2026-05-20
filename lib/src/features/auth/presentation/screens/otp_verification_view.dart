import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_background_widget.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_glass_card.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/otp_pin_input_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Screen 2 — Enter the 6-digit OTP sent to the user's phone.
class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key});

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _onContinue(BuildContext context, AuthViewModel vm) async {
    final success = await vm.verifyOtp();
    if (success && context.mounted) {
      await context.push<void>(RoutePaths.setupPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final isForgotPin = vm.isForgotPinFlow;

    return AuthBackgroundWidget(
      child: Column(
        children: [
          const SizedBox(height: 80),

          // ── Screen title ─────────────────────────────────
          Center(
            child: Text(
              isForgotPin ? 'XÁC THỰC ĐẶT LẠI PIN' : 'XÁC THỰC',
              style: AppTextStyles.authScreenTitle,
            ),
          ),

          const SizedBox(height: 28),

          // ── Glass card ───────────────────────────────────
          AuthGlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "OTP sent to"
                    Text(
                      isForgotPin
                          ? 'Mã OTP đã được gửi để đặt lại mã PIN'
                          : 'Mã OTP đã được gửi đến',
                      style: AppTextStyles.bodyWhite.copyWith(
                        color: AppColors.authTextLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Phone number
                    Text(
                      vm.phoneNumber.isNotEmpty ? vm.phoneNumber : '0904132611',
                      style: AppTextStyles.authPhoneDisplay,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 33),

                    // OTP Input
                    FormBuilderField<String>(
                      name: 'otp',
                      builder: (field) {
                        return OtpPinInputWidget(
                          isLoading: vm.isLoading,
                          autoFocus: true,
                          onCompleted: (value) async {
                            field.didChange(value);
                            vm.otp = value;
                            if (context.mounted) {
                              await _onContinue(context, vm);
                            }
                          },
                          onChanged: (value) {
                            field.didChange(value);
                            vm.otp = value;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 5),

                    // Resend OTP
                    InkWell(
                      onTap: () async => vm.submitPhone(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 8, bottom: 9),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.authInputBorder,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                            child: Text(
                              'Gửi lại',
                              style: AppTextStyles.bodyWhite.copyWith(
                                color: AppColors.authTextSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // API Error from ViewModel (placed below resend for better visual flow or wherever error occurs, here it's fine)
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],

                    // const SizedBox(height: 64),

                    // // Continue button
                    // AuthActionButton(
                    //   text: 'TIẾP TỤC',
                    //   isLoading: vm.isLoading,
                    //   onPressed: () => _onContinue(context, vm),
                    // ),
                    const SizedBox(height: 45),

                    // ── Switch account ───────────────────────────────
                    RichText(
                      text: TextSpan(
                        text: isForgotPin
                            ? 'Quay lại đăng nhập bằng PIN? '
                            : 'Truy cập bằng tài khoản khác ? ',
                        style: AppTextStyles.bodyWhite.copyWith(
                          color: AppColors.authTextSecondary, // #B9B0AC
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: isForgotPin ? 'Quay lại' : 'Đăng nhập',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (isForgotPin) {
                                  vm.cancelForgotPin();
                                  context.go(RoutePaths.pinLogin);
                                } else {
                                  vm.reset();
                                  context.go(RoutePaths.phoneLogin);
                                }
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
