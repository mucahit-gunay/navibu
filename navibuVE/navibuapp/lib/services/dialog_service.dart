import 'package:flutter/material.dart';
import '../widgets/custom_dialog.dart';

class DialogService {
  static Future<void> showLoading(
    BuildContext context, {
    String message = 'Lütfen bekleyin...',
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomDialog(
        message: message,
        animationAsset: 'assets/animations/loading.json',
      ),
    );
  }

  static Future<void> showSuccess(
    BuildContext context, {
    String message = 'İşlem başarılı!',
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomDialog(
        message: message,
        animationAsset: 'assets/animations/success.json',
        textColor: Colors.green,
        autoDismiss: true,
        onDismiss: onDismiss,
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    String message = 'Bir hata oluştu!',
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CustomDialog(
        message: message,
        animationAsset: 'assets/animations/error.json',
        textColor: Colors.red,
        onDismiss: onDismiss,
      ),
    );
  }
}