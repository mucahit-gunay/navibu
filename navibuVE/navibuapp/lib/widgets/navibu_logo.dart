// lib/widgets/navibu_logo.dart
import 'package:flutter/material.dart';

class NavibuLogo extends StatelessWidget {
  const NavibuLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/navibu_logo.png',
      width: 150,
      height: 150,
      fit: BoxFit.contain,
    );
  }
}