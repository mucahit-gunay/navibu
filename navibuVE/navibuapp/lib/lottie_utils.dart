import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


/// 1. Function name : loadAnimation and parameters
  /// [animationName]: Name of the JSON file (without extension)
  /// [width]: Width of the animation (optional)
  /// [height]: Height of the animation (optional)
  /// [fit]: How the animation should be fitted (default: BoxFit.contain)
  /// [repeat]: Whether the animation should repeat (default: true)
  /// [animate]: Whether the animation should animate (default: true)
  /// [reverse]: Whether the animation should play in reverse (default: false)

/// Additional functions will be added as needed
///
class LottieUtils {
  LottieUtils._();

  static const String _basePath = 'assets/animations/';
  static Widget loadAnimation(
    String animationName, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
    bool animate = true,
    bool reverse = false,
  }) {
    final String path = '$_basePath$animationName.json';
    return Lottie.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      reverse: reverse,
    );
  }
}
