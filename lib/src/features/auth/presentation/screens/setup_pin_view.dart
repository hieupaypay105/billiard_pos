import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/auth_view_model.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_background_widget.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_glass_card.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/otp_pin_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Screen 3 — Create a new 6-digit PIN.
class SetupPinView extends StatefulWidget {
  const SetupPinView({super.key});

  @override
  State<SetupPinView> createState() => _SetupPinViewState();
}

class _SetupPinViewState extends State<SetupPinView> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _onConfirmPin(BuildContext context, AuthViewModel vm) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      if (context.mounted) {
        await context.push<void>(RoutePaths.confirmPin);
      }
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
              'THIẾT LẬP THÔNG TIN',
              style: AppTextStyles.authScreenTitle.copyWith(
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Glass card ───────────────────────────────────
          AuthGlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Thiết lập mã PIN',
                      style: AppTextStyles.bodyWhite.copyWith(
                        color: AppColors.authTextLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Instruction
                    Text(
                      'Mã PIN dùng để bảo mật và xác thực tài khoản',
                      style: AppTextStyles.bodyWhite.copyWith(
                        color: AppColors.authTextLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    // Setup PIN Input
                    FormBuilderField<String>(
                      name: 'setup_pin',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập mã PIN',
                        ),
                        FormBuilderValidators.minLength(
                          6,
                          errorText: 'Mã PIN phải đủ 6 số',
                        ),
                      ]),
                      builder: (field) {
                        return OtpPinInputWidget(
                          isLoading: vm.isLoading,
                          autoFocus: true,
                          obscureText: true,
                          boxSize: 38,
                          onCompleted: (value) async {
                            field.didChange(value);
                            vm.pin = value;
                            if (context.mounted) {
                              await _onConfirmPin(context, vm);
                            }
                          },
                          onChanged: (value) {
                            field.didChange(value);
                            vm.pin = value;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 64),

                    // Error from ViewModel
                    if (vm.errorMessage != null) ...[
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // const SizedBox(height: 36),

                    // // Buttons (Commented out per user request, using auto-submit upon completion)
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: AuthOutlinedButton(
                    //         text: '← QUAY LẠI',
                    //         onPressed: () {
                    //           if (isForgotPin) {
                    //             vm.cancelForgotPin();
                    //             context.go(RoutePaths.pinLogin);
                    //           } else {
                    //             vm.reset();
                    //             context.go(RoutePaths.phoneLogin);
                    //           }
                    //         },
                    //       ),
                    //     ),
                    //     const SizedBox(width: 16),
                    //     Expanded(
                    //       child: AuthActionButton(
                    //         text: 'TIẾP TỤC →',
                    //         isLoading: vm.isLoading,
                    //         onPressed: () => _onConfirmPin(context, vm),
                    //       ),
                    //     ),
                    //   ],
                    // ),
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
