// lib/screens/verification_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:navibuapp/widgets/navibu_logo.dart';
import 'package:navibuapp/screens/login_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  VerificationScreen({required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  TextEditingController codeController = TextEditingController();
  bool isLoading = false;
  String message = "";

  Future<void> verifyCode() async {
    setState(() {
      isLoading = true;
      message = "";
    });

    try {
      // Replace with your computer's actual IP address
      final url = Uri.parse("http://127.0.0.1:5000/auth/verify");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "code": codeController.text,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        // Show success message with timer
        setState(() {
          message = "Doğrulama başarılı! Giriş ekranına yönlendiriliyorsunuz...";
        });
        
        // Navigate to login after delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          message = data["message"] ?? "Doğrulama başarısız!";
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
                  "Hesabınızı Doğrulayın",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Instructions
                Text(
                  "${widget.email} adresine gönderilen 6 haneli doğrulama kodunu giriniz.",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Code field
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: "Doğrulama Kodu",
                    prefixIcon: Icon(Icons.pin),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                ),
                const SizedBox(height: 24),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyCode,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Doğrula"),
                  ),
                ),
                const SizedBox(height: 16),
                // Message
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: message.contains("başarılı") ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}