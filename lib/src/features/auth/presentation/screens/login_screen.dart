import 'package:anholding_app/src/features/auth/presentation/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Key quản lý trạng thái form (Validate, Save, Get Value)
  final _formKey = GlobalKey<FormBuilderState>();

  // Trạng thái hiển thị mật khẩu
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Branding
              const Icon(
                Icons.business_center_rounded,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'ANHOLDING CRM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập hệ thống quản lý',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // --- FORM BUILDER BẮT ĐẦU TỪ ĐÂY ---
              FormBuilder(
                key: _formKey,
                // Giá trị mặc định (dùng để test nhanh)
                initialValue: const {
                  'username': 'admin',
                  'password': 'Trannghia@123',
                },
                child: Column(
                  children: [
                    // 1. Username Field
                    FormBuilderTextField(
                      name: 'username', // Tên định danh field
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập tên đăng nhập',
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // 2. Password Field
                    FormBuilderTextField(
                      name: 'password',
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập mật khẩu',
                        ),
                        FormBuilderValidators.minLength(
                          6,
                          errorText: 'Mật khẩu tối thiểu 6 ký tự',
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Login Button & Logic
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hiển thị lỗi nếu có
                      if (auth.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.errorMessage ?? '',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                // BƯỚC QUAN TRỌNG: Save & Validate
                                if (_formKey.currentState?.saveAndValidate() ??
                                    false) {
                                  final formData = _formKey.currentState!.value;
                                  final username =
                                      formData['username'] as String? ?? '';
                                  final password =
                                      formData['password'] as String? ?? '';

                                  // Giữ reference router trước await để sau khi login vẫn go được
                                  final router = GoRouter.of(context);

                                  final success = await auth.login(
                                    username,
                                    password,
                                  );

                                  if (success) {
                                    router.go('/dashboard');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đăng nhập thành công!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  print('Validation Failed');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ĐĂNG NHẬP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
