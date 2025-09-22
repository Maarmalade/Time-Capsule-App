import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_profile_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/error_display_widget.dart';

class EditUsernamePage extends StatefulWidget {
  final String currentUsername;

  const EditUsernamePage({
    super.key,
    required this.currentUsername,
  });

  @override
  State<EditUsernamePage> createState() => _EditUsernamePageState();
}

class _EditUsernamePageState extends State<EditUsernamePage> {
  final TextEditingController _usernameController = TextEditingController();
  final UserProfileService _userProfileService = UserProfileService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  String? _errorMessage;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username == widget.currentUsername) {
      setState(() {
        _availabilityMessage = null;
        _isCheckingAvailability = false;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        _availabilityMessage = null;
        _isCheckingAvailability = false;
      });
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = null;
    });

    try {
      final isAvailable = await _userProfileService.isUsernameAvailable(username);
      setState(() {
        _availabilityMessage = isAvailable 
            ? 'Username is available!' 
            : 'Username is already taken';
        _isCheckingAvailability = false;
      });
    } catch (e) {
      setState(() {
        _availabilityMessage = 'Unable to check availability';
        _isCheckingAvailability = false;
      });
    }
  }

  String? _validateUsername(String? value) {
    return ValidationUtils.validateUsername(value);
  }

  Future<void> _updateUsername() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newUsername = _usernameController.text.trim();
    
    if (newUsername == widget.currentUsername) {
      Navigator.of(context).pop(false); // No changes made
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _userProfileService.updateUsername(user.uid, newUsername);
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'Username updated successfully!');
        Navigator.of(context).pop(true); // Changes made
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
        title: const Text('Edit Username'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateUsername,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.black54 : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a new username',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your username is how others will find and identify you.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isCheckingAvailability
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _availabilityMessage != null
                          ? Icon(
                              _availabilityMessage!.contains('available')
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _availabilityMessage!.contains('available')
                                  ? Colors.green
                                  : Colors.red,
                            )
                          : null,
                ),
                validator: _validateUsername,
                onChanged: (value) {
                  // Debounce the availability check
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_usernameController.text == value) {
                      _checkUsernameAvailability(value);
                    }
                  });
                },
              ),
              
              if (_availabilityMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _availabilityMessage!,
                  style: TextStyle(
                    color: _availabilityMessage!.contains('available')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
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
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Username Requirements',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• 3-20 characters long'),
                    const Text('• Letters, numbers, and underscores only'),
                    const Text('• Must be unique'),
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
                  onPressed: _isLoading ? null : _updateUsername,
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
                          'Update Username',
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