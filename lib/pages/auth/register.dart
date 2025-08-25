import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/route_constants.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _error = '';
  bool _loading = false;

  Future<void> _register() async {
    setState(() {
      _error = '';
      _loading = true;
    });

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Passwords do not match';
        _loading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _loading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primaryWhite,
            ),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pushReplacementNamed(context, Routes.usernameSetup);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Registration failed';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.pageAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: AppSpacing.iconSizeLarge,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      AppSpacing.minTouchTarget,
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Time Capsule',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Sign Up',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildTextField(_emailController, 'Enter Email'),
                      const SizedBox(height: AppSpacing.md),
                      _buildTextField(
                        _passwordController,
                        'Enter Password',
                        obscure: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildTextField(
                        _confirmController,
                        'Confirm Password',
                        obscure: true,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_error.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                              color: AppColors.errorRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _error,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      SizedBox(
                        width: 200,
                        height: AppSpacing.minTouchTarget,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryWhite,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: AppTypography.buttonText,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(
            color: AppColors.accentBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: BorderSide(
            color: AppColors.errorRed,
            width: 2,
          ),
        ),
        contentPadding: AppSpacing.inputPadding,
      ),
    );
  }
}
