import 'package:flutter/material.dart';
import 'pages/auth/login.dart';
import 'pages/auth/register.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case Routes.register:
      return MaterialPageRoute(builder: (_) => const RegisterPage());
    case Routes.home:
      return MaterialPageRoute(builder: (_) => const HomePage());
    default:
      return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}

// Simple home page for "Time Capsule App is running!"
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Time Capsule App is running!',
          style: TextStyle(fontSize: 24, color: Colors.deepPurple),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Time Capsule App',
    initialRoute: Routes.login,
    onGenerateRoute: generateRoute,
  ));
}