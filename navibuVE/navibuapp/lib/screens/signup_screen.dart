// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/navibu_logo.dart';
import '../screens/verification_screen.dart';
import '../services/dialog_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

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
                  "Hesap Oluştur",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 30),
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
                SizedBox(height: 16),
                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Confirm Password field
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
                SizedBox(height: 30),
                // Sign up button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Kayıt Ol',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Zaten hesabınız var mı?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Giriş Yap'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> signUp() async {
    // Validate passwords match
    if (passwordController.text != confirmPasswordController.text) {
      DialogService.showError(
        context,
        message: 'Şifreler eşleşmiyor!',
      );
      return;
    }

    // Validate fields are not empty
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      DialogService.showError(
        context,
        message: 'Tüm alanları doldurunuz!',
      );
      return;
    }

    // Show loading dialog
    await DialogService.showLoading(context, message: 'Kayıt yapılıyor...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 201) {
        // Show success dialog
        await DialogService.showSuccess(
          context,
          message: 'Kayıt Başarılı!\nLütfen e-postanızı doğrulayın.',
          onDismiss: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  email: emailController.text,
                ),
              ),
            );
          },
        );
      } else {
        final data = jsonDecode(response.body);
        DialogService.showError(
          context,
          message: data['error'] ?? 'Kayıt işlemi başarısız!',
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}