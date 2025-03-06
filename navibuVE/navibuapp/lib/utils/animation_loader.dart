import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TAnimationLoader {
  static Widget loading({
    double? width = 200,
    double? height = 200,
  }) {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading.json',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget error({
    double? width = 200,
    double? height = 200,
  }) {
    return Center(
      child: Lottie.asset(
        'assets/animations/error.json',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget success({
    double? width = 200,
    double? height = 200,
  }) {
    return Center(
      child: Lottie.asset(
        'assets/animations/success.json',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
} 