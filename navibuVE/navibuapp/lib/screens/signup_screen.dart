// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:navibuapp/widgets/navibu_logo.dart';
import 'package:navibuapp/screens/verification_screen.dart';
import 'package:navibuapp/screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String message = "";

  Future<void> signUpUser() async {
    // First, validate passwords match
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        message = "Şifreler eşleşmiyor!";
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = "";
    });

    try {
      // Replace with your computer's actual IP address
      final url = Uri.parse("http://127.0.0.1:5000/auth/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(email: emailController.text),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          message = data["error"] ?? "Kayıt başarısız!";
        });
      }
    } catch (e) {
      setState(() {
        message = "Bağlantı hatası: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                const Center(child: NavibuLogo()),
                const SizedBox(height: 40),
                // Title
                Text(
                  "Yeni Hesap Oluştur",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Email field
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password field
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                // Confirm password field
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: "Şifreyi Onayla",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                // Signup button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUpUser,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Kayıt Ol"),
                  ),
                ),
                const SizedBox(height: 16),
                // Error message
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Zaten hesabınız var mı?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: const Text("Giriş Yap"),
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
}