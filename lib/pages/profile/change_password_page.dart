import 'package:flutter/material.dart';
import '../../services/user_profile_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/error_display_widget.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final UserProfileService _userProfileService = UserProfileService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    return ValidationUtils.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    return ValidationUtils.validatePasswordConfirmation(_newPasswordController.text, value);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userProfileService.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Password updated successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update your password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new secure password.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Current Password Field
              TextFormField(
                controller: _currentPasswordController,
                enabled: !_isLoading,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: _validateCurrentPassword,
              ),
              const SizedBox(height: 16),
              
              // New Password Field
              TextFormField(
                controller: _newPasswordController,
                enabled: !_isLoading,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                validator: _validateNewPassword,
                onChanged: (value) {
                  // Trigger validation for confirm password field if it has content
                  if (_confirmPasswordController.text.isNotEmpty) {
                    _formKey.currentState!.validate();
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),
              
              // Password Requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Password Requirements',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• At least 6 characters long'),
                    const Text('• Use a combination of letters, numbers, and symbols'),
                    const Text('• Avoid using personal information'),
                  ],
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorDisplayWidget(
                  message: _errorMessage!,
                  onRetry: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey, width: 1),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}