import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_profile_service.dart';
import '../home/home_page.dart';
import '../../utils/error_handler.dart';
import '../../utils/validation_utils.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';

class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({super.key});

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final _usernameController = TextEditingController();
  final _userProfileService = UserProfileService();
  
  String _error = '';
  bool _loading = false;
  bool _checkingAvailability = false;
  String _availabilityMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _availabilityMessage = '';
      });
      return;
    }

    // Validate format first
    final validationError = ValidationUtils.validateUsername(username);
    if (validationError != null) {
      setState(() {
        _availabilityMessage = validationError;
      });
      return;
    }

    setState(() {
      _checkingAvailability = true;
      _availabilityMessage = 'Checking availability...';
    });

    try {
      final isAvailable = await _userProfileService.isUsernameAvailable(username);
      setState(() {
        _checkingAvailability = false;
        _availabilityMessage = isAvailable 
            ? '✓ Username is available' 
            : '✗ Username already taken';
      });
    } catch (e) {
      setState(() {
        _checkingAvailability = false;
        _availabilityMessage = ErrorHandler.getErrorMessage(e);
      });
    }
  }



  Future<void> _createUsername() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _error = 'Please enter a username';
      });
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _userProfileService.createUserProfile(
        user.uid,
        username,
        user.email ?? '',
      );

      setState(() {
        _loading = false;
      });

      if (!mounted) return;
      
      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
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
                        'Choose Your Username',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Create a unique username to personalize your Time Capsule experience.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Username',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildUsernameField(),
                      const SizedBox(height: AppSpacing.sm),
                      if (_availabilityMessage.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _availabilityMessage,
                            style: AppTypography.bodySmall.copyWith(
                              color: _availabilityMessage.startsWith('✓') 
                                  ? AppColors.successGreen 
                                  : _availabilityMessage.startsWith('✗')
                                      ? AppColors.errorRed
                                      : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Username requirements:',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '• 3-20 characters\n• Letters, numbers, and underscores only\n• Must be unique',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Container(
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
                        ),
                      SizedBox(
                        width: 200,
                        height: AppSpacing.minTouchTarget,
                        child: ElevatedButton(
                          onPressed: (_loading || _checkingAvailability || 
                                     !_availabilityMessage.startsWith('✓')) 
                              ? null 
                              : _createUsername,
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

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      onChanged: (_) {
        // Debounce the availability check
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_usernameController.text.trim().isNotEmpty) {
            _checkUsernameAvailability();
          }
        });
      },
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your username',
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
        suffixIcon: _checkingAvailability
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentBlue,
                    ),
                  ),
                ),
              )
            : _availabilityMessage.startsWith('✓')
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: AppSpacing.iconSize,
                  )
                : _availabilityMessage.startsWith('✗')
                    ? Icon(
                        Icons.error,
                        color: AppColors.errorRed,
                        size: AppSpacing.iconSize,
                      )
                    : null,
      ),
    );
  }
}