import 'package:flutter/material.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textMultiplier;
  static late double heightMultiplier;
  static late double widthMultiplier;
  static late bool isPortrait;
  static late bool isMobilePortrait;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    isPortrait = _mediaQueryData.orientation == Orientation.portrait;
    
    if (isPortrait) {
      blockSizeHorizontal = screenWidth / 100;
      blockSizeVertical = screenHeight / 100;
    } else {
      blockSizeHorizontal = screenHeight / 100;
      blockSizeVertical = screenWidth / 100;
    }

    textMultiplier = blockSizeVertical;
    heightMultiplier = blockSizeVertical;
    widthMultiplier = blockSizeHorizontal;
    isMobilePortrait = isPortrait && screenWidth < 600;
  }

  static double getProportionateScreenHeight(double inputHeight) {
    double screenHeight = SizeConfig.screenHeight;
    // 812 is the layout height that designer use
    return (inputHeight / 812.0) * screenHeight;
  }

  static double getProportionateScreenWidth(double inputWidth) {
    double screenWidth = SizeConfig.screenWidth;
    // 375 is the layout width that designer use
    return (inputWidth / 375.0) * screenWidth;
  }
}

// Extension methods for responsive sizing
extension SizeExtension on num {
  double get h => this * SizeConfig.heightMultiplier;
  double get w => this * SizeConfig.widthMultiplier;
  double get sp => this * SizeConfig.textMultiplier;
}