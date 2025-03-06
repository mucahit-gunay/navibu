import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/size_config.dart';

class CustomDialog extends StatelessWidget {
  final String message;
  final String animationAsset;
  final Color textColor;
  final VoidCallback? onDismiss;
  final bool autoDismiss;
  final Duration autoDismissDuration;

  const CustomDialog({
    Key? key,
    required this.message,
    required this.animationAsset,
    this.textColor = Colors.black87,
    this.onDismiss,
    this.autoDismiss = false,
    this.autoDismissDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (autoDismiss) {
      Future.delayed(autoDismissDuration, () {
        Navigator.of(context).pop();
        if (onDismiss != null) {
          onDismiss!();
        }
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 80.w,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LottieBuilder.asset(
              animationAsset,
              width: 100,
              height: 100,
              repeat: animationAsset.contains('loading'),
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 