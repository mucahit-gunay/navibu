import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = false;
  String? _error;

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
                // Error message if exists
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
                      onPressed: _isLoading ? null : sendResetCode,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
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
                      onPressed: _isLoading ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Şifre Sıfırla',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Resend code button
                  TextButton(
                    onPressed: _isLoading ? null : sendResetCode,
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
      setState(() {
        _error = 'Lütfen e-posta adresinizi girin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await (
        authService.requestPasswordReset(emailController.text));

      setState(() {
        _isLoading = false;
        if (!codeSent) codeSent = true;
      });
      
      if (mounted) {
        DialogService.showSuccess(
          context,
          message: response['message'] ?? 'Şifre sıfırlama kodu e-posta adresinize gönderildi.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> resetPassword() async {
    if (codeController.text.isEmpty || 
        newPasswordController.text.isEmpty || 
        confirmPasswordController.text.isEmpty) {
      setState(() {
        _error = 'Lütfen tüm alanları doldurun.';
      });
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        _error = 'Şifreler eşleşmiyor.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.post(
        '/auth/reset-password',
        data: {
          'email': emailController.text,
          'code': codeController.text,
          'new_password': newPasswordController.text,
        },
      );

      if (response['success']) {
        if (mounted) {
          await DialogService.showSuccess(
            context,
            message: 'Şifreniz başarıyla sıfırlandı!',
            onDismiss: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = response['message'] ?? 'Şifre sıfırlanamadı. Lütfen tekrar deneyin.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.';
      });
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