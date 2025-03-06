import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class THelpers {
  static String formatDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount);
  }

  static bool isEmailValid(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  static bool isPasswordValid(String password) {
    return password.length >= 6;
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Evet',
    String cancelLabel = 'Hayır',
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
} 