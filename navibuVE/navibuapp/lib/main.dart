// lib/main.dart
import 'package:flutter/material.dart';
import 'package:navibuapp/screens/login_screen.dart';
import 'package:navibuapp/theme/theme.dart';
import 'package:navibuapp/utils/size_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navibu',
      theme: NavibuTheme.theme,
      home: Builder(
        builder: (context) {
          SizeConfig().init(context);
          return LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
