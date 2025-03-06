// lib/screens/verification_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/navibu_logo.dart';
import '../screens/login_screen.dart';
import '../services/dialog_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  VerificationScreen({required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('E-posta Doğrulama'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                // Logo
                Center(child: NavibuLogo()),
                SizedBox(height: 30),
                // Info text
                Text(
                  "Doğrulama Kodu",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Lütfen ${widget.email} adresine gönderilen 6 haneli doğrulama kodunu girin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                // Code field
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, letterSpacing: 10),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "000000",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: verifyCode,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Doğrula',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Resend code
                TextButton(
                  onPressed: resendCode,
                  child: Text('Kodu Tekrar Gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verifyCode() async {
    if (codeController.text.isEmpty || codeController.text.length < 6) {
      DialogService.showError(
        context,
        message: 'Lütfen 6 haneli doğrulama kodunu girin.',
      );
      return;
    }

    await DialogService.showLoading(context, message: 'Doğrulanıyor...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': codeController.text,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        await DialogService.showSuccess(
          context,
          message: 'Hesabınız başarıyla doğrulandı!',
          onDismiss: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          },
        );
      } else {
        final data = jsonDecode(response.body);
        DialogService.showError(
          context,
          message: data['message'] ?? 'Doğrulama başarısız!',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        DialogService.showError(
          context,
          message: 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.',
        );
      }
    }
  }

  Future<void> resendCode() async {
    await DialogService.showLoading(context, message: 'Kod yeniden gönderiliyor...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        DialogService.showSuccess(
          context,
          message: 'Doğrulama kodu yeniden gönderildi!',
        );
      } else {
        final data = jsonDecode(response.body);
        DialogService.showError(
          context,
          message: data['message'] ?? 'Kod gönderilemedi!',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        DialogService.showError(
          context,
          message: 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.',
        );
      }
    }
  }
}