import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/navibu_logo.dart';
import '../services/dialog_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool codeSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                // Title
                Text(
                  "Şifre Sıfırlama",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                // Description text
                Text(
                  codeSent 
                      ? "E-posta adresinize gönderilen kodu girin ve yeni şifrenizi belirleyin."
                      : "Şifrenizi sıfırlamak için e-posta adresinizi girin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                
                // Form
                if (!codeSent) ...[
                  // Email field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "E-posta",
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Send code button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: sendResetCode,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Kod Gönder',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  // Code field
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "Kod",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: "",
                    ),
                  ),
                  SizedBox(height: 16),
                  // New password field
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Yeni Şifre",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Confirm password field
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Şifre Tekrar",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Reset password button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Şifre Sıfırla',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Resend code button
                  TextButton(
                    onPressed: sendResetCode,
                    child: Text('Kodu Tekrar Gönder'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendResetCode() async {
    if (emailController.text.isEmpty) {
      DialogService.showError(
        context,
        message: 'Lütfen e-posta adresinizi girin.',
      );
      return;
    }

    await DialogService.showLoading(context, message: 'Kod gönderiliyor...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        setState(() {
          codeSent = true;
        });
        
        DialogService.showSuccess(
          context,
          message: 'Şifre sıfırlama kodu e-posta adresinize gönderildi.',
        );
      } else {
        final data = jsonDecode(response.body);
        DialogService.showError(
          context,
          message: data['error'] ?? 'Şifre sıfırlama kodu gönderilemedi.',
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

  Future<void> resetPassword() async {
    if (codeController.text.isEmpty || 
        newPasswordController.text.isEmpty || 
        confirmPasswordController.text.isEmpty) {
      DialogService.showError(
        context,
        message: 'Lütfen tüm alanları doldurun.',
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      DialogService.showError(
        context,
        message: 'Şifreler eşleşmiyor.',
      );
      return;
    }

    await DialogService.showLoading(context, message: 'Şifre sıfırlanıyor...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'code': codeController.text,
          'new_password': newPasswordController.text,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        await DialogService.showSuccess(
          context,
          message: 'Şifreniz başarıyla sıfırlandı!',
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
          message: data['error'] ?? 'Şifre sıfırlama başarısız.',
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

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
} 