import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_profile_service.dart';
import '../home/home_page.dart';
import '../../utils/error_handler.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/error_display_widget.dart';

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

  bool _isValidUsernameFormat(String username) {
    return ValidationUtils.validateUsername(username) == null;
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Time Capsule',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Choose Your Username',
                        style: TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create a unique username to personalize your Time Capsule experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Username', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      _buildUsernameField(),
                      const SizedBox(height: 8),
                      if (_availabilityMessage.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _availabilityMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: _availabilityMessage.startsWith('✓') 
                                  ? Colors.green 
                                  : _availabilityMessage.startsWith('✗')
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Username requirements:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '• 3-20 characters\n• Letters, numbers, and underscores only\n• Must be unique',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ErrorDisplayWidget(
                            message: _error,
                            showIcon: false,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_loading || _checkingAvailability || 
                                     !_availabilityMessage.startsWith('✓')) 
                              ? null 
                              : _createUsername,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(color: Colors.black),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 4,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator()
                              : const Text('Continue'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _usernameController,
        onChanged: (_) {
          // Debounce the availability check
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_usernameController.text.trim().isNotEmpty) {
              _checkUsernameAvailability();
            }
          });
        },
        decoration: const InputDecoration(
          hintText: 'Enter your username',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}