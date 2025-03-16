// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:navibuapp/screens/login_screen.dart';
import 'package:navibuapp/screens/home_screen.dart';
import 'package:navibuapp/screens/signup_screen.dart';
import 'package:navibuapp/screens/forgot_password_screen.dart';
import 'package:navibuapp/screens/route_selection_screen.dart';
import 'package:navibuapp/screens/verification_screen.dart';
import 'package:navibuapp/theme/theme.dart';
import 'package:navibuapp/utils/size_config.dart';
import 'package:navibuapp/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService(),
      child: Builder(
        builder: (context) {
          SizeConfig().init(context);
          return MaterialApp(
            title: 'Navibu',
            theme: NavibuTheme.theme,
            initialRoute: '/login',
            onGenerateRoute: (settings) {
              if (settings.name == '/route-selection') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => RouteSelectionScreen(
                    userId: args['userId'] as int,
                  ),
                );
              }
              return null;
            },
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/signup': (context) =>  SignupScreen(),
              '/forgot-password': (context) =>  ForgotPasswordScreen(),
              '/verify': (context) =>  VerificationScreen(email: '',),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
