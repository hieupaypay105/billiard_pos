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

/// Screen 4 — Confirm the newly created PIN.
class ConfirmPinView extends StatefulWidget {
  const ConfirmPinView({super.key});

  @override
  State<ConfirmPinView> createState() => _ConfirmPinViewState();
}

class _ConfirmPinViewState extends State<ConfirmPinView> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _onSubmit(BuildContext context, AuthViewModel vm) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final confirmPin = _formKey.currentState?.value['confirm_pin'] as String?;

      if (confirmPin != vm.pin) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã PIN không khớp. Vui lòng kiểm tra lại.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final success = await vm.confirmAndSetPin();
      if (success && context.mounted) {
        if (vm.isForgotPinFlow) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đổi mã PIN thành công!')),
          );
          vm.cancelForgotPin();
          context.go(RoutePaths.pinLogin);
        } else {
          context.go(RoutePaths.dashboard);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

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
                      'Xác nhận mã PIN',
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

                    // Confirm PIN Input
                    FormBuilderField<String>(
                      name: 'confirm_pin',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập lại mã PIN',
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
                            vm.confirmPin = value;
                            if (context.mounted) {
                              await _onSubmit(context, vm);
                            }
                          },
                          onChanged: (value) {
                            field.didChange(value);
                            vm.confirmPin = value;
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
                    //         onPressed: () => context.pop(),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 16),
                    //     Expanded(
                    //       child: AuthActionButton(
                    //         text: 'TIẾP TỤC →',
                    //         isLoading: vm.isLoading,
                    //         onPressed: () => _onSubmit(context, vm),
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
