import 'package:flutter/material.dart';
import 'pages/auth/login.dart';
import 'pages/auth/register.dart';
import 'pages/auth/username_setup_page.dart';
import 'pages/home/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_username_page.dart';
import 'pages/profile/change_password_page.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String usernameSetup = '/username-setup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editUsername = '/edit-username';
  static const String changePassword = '/change-password';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case Routes.register:
      return MaterialPageRoute(builder: (_) => const RegisterPage());
    case Routes.usernameSetup:
      return MaterialPageRoute(builder: (_) => const UsernameSetupPage());
    case Routes.home:
      return MaterialPageRoute(builder: (_) => const HomePage());
    case Routes.profile:
      return MaterialPageRoute(builder: (_) => const ProfilePage());
    case Routes.editUsername:
      final args = settings.arguments as Map<String, dynamic>?;
      final currentUsername = args?['currentUsername'] as String? ?? '';
      return MaterialPageRoute(
        builder: (_) => EditUsernamePage(currentUsername: currentUsername),
      );
    case Routes.changePassword:
      return MaterialPageRoute(builder: (_) => const ChangePasswordPage());
    default:
      return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}

