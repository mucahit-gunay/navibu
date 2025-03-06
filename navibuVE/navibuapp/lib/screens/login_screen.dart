import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/navibu_logo.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/route_selection_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../services/dialog_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                // Logo
                Center(child: NavibuLogo()),
                SizedBox(height: 40),
                // Title
                Text(
                  "Navibu'ya Hoş Geldiniz",
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
                SizedBox(height: 24),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loginUser,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Giriş Yap',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Forgot password button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text('Şifremi Unuttum'),
                ),
                SizedBox(height: 16),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hesabınız yok mu?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text('Kayıt Ol'),
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

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      DialogService.showError(
        context,
        message: 'E-posta ve şifre alanları boş bırakılamaz',
      );
      return;
    }

    await DialogService.showLoading(context, message: 'Giriş yapılıyor...');

    try {
      final response = await http.post(
        Uri.parse("http://localhost:5000/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data["user_id"];

        // Check user routes
        await checkUserRoutes(userId);
      } else {
        final data = jsonDecode(response.body);
        DialogService.showError(
          context,
          message: data["error"] ?? "Giriş başarısız!",
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

  Future<void> checkUserRoutes(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/auth/check-routes?user_id=$userId'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hasRoutes = data['has_routes'];

        await DialogService.showSuccess(
          context,
          message: 'Giriş Başarılı!',
          onDismiss: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => hasRoutes 
                    ? HomeScreen(userId: userId)
                    : RouteSelectionScreen(userId: userId),
              ),
            );
          },
        );
      }
    } catch (e) {
      DialogService.showError(
        context,
        message: 'Rota kontrolü sırasında bir hata oluştu.',
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}