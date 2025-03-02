import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class THelperFunctions {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static Future<void> showAlert(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static Future<void> navigateToScreen(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String getFormattedDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String getFormattedTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }
} 