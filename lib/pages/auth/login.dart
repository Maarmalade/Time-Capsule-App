import 'package:flutter/material.dart';
import '../../constants/route_constants.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String _error = '';
  bool _loading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  Future<void> _login() async {
    setState(() {
      _error = '';
      _loading = true;
    });

    final result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _loading = false;
    });

    if (result.isSuccess) {
      // Show success message if provided
      if (result.message != null && mounted) {
        ErrorHandler.showSuccessSnackBar(context, result.message!);
      }
      
      // Force navigation to home page after successful login
      // This ensures navigation happens even if StreamBuilder doesn't update immediately
      if (mounted) {
        debugPrint('Login: Success, forcing navigation to home');
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.home,
          (route) => false, // Remove all previous routes
        );
      }
    } else {
      setState(() {
        _error = result.error ?? 'Login failed. Please try again.';
      });
      
      // Show user-friendly error message
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          message: _error,
          onRetry: _login,
        );
      }
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
                const SizedBox(height: AppSpacing.xl),
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
                        'Login',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTextField(_emailController, 'john@email.com'),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildPasswordField(
                        _passwordController,
                        'Enter password',
                        _passwordVisible,
                        () => setState(() => _passwordVisible = !_passwordVisible),
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
                          onPressed: _loading ? null : _login,
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
                                  'Continue',
                                  style: AppTypography.buttonText,
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.register);
                        },
                        child: Text(
                          "Don't have an account?\nSign up here",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: AppTypography.medium,
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
            color: AppColors.primaryAccent,
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

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool isVisible,
    VoidCallback onToggleVisibility,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
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
            color: AppColors.primaryAccent,
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
        suffixIcon: Semantics(
          label: isVisible ? 'Hide password' : 'Show password',
          button: true,
          child: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textTertiary,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }
}
