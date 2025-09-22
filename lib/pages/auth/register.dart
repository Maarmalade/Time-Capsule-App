import 'package:flutter/material.dart';
import '../../constants/route_constants.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  String _error = '';
  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {}); // Rebuild to update password requirements
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isPasswordValid(String password) {
    return password.length >= 6 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  Future<void> _register() async {
    setState(() {
      _error = '';
      _loading = true;
    });

    if (!_isPasswordValid(_passwordController.text)) {
      setState(() {
        _error = 'Password does not meet requirements';
        _loading = false;
      });
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Passwords do not match';
        _loading = false;
      });
      return;
    }

    final result = await _authService.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _loading = false;
    });

    if (result.isSuccess) {
      if (!mounted) return;
      
      // Show success message
      ErrorHandler.showSuccessSnackBar(
        context, 
        result.message ?? 'Account created successfully!'
      );
      
      Navigator.pushReplacementNamed(context, Routes.usernameSetup);
    } else {
      setState(() {
        _error = result.error ?? 'Registration failed. Please try again.';
      });
      
      // Show user-friendly error message
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          message: _error,
          onRetry: _register,
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
                      _buildPasswordField(
                        _passwordController,
                        'Enter Password',
                        _passwordVisible,
                        () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildPasswordRequirements(),
                      const SizedBox(height: AppSpacing.md),
                      _buildPasswordField(
                        _confirmController,
                        'Confirm Password',
                        _confirmPasswordVisible,
                        () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
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

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildRequirementItem(
            'At least 6 characters',
            password.length >= 6,
          ),
          _buildRequirementItem(
            'One uppercase letter',
            password.contains(RegExp(r'[A-Z]')),
          ),
          _buildRequirementItem(
            'One lowercase letter',
            password.contains(RegExp(r'[a-z]')),
          ),
          _buildRequirementItem(
            'One number',
            password.contains(RegExp(r'[0-9]')),
          ),
          _buildRequirementItem(
            'One special symbol',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppColors.successGreen : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: isMet ? AppColors.successGreen : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
