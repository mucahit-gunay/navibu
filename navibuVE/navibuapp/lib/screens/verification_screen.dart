// lib/screens/verification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = false;

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
                    onPressed: _isLoading ? null : verifyCode,
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
                            'Doğrula',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                SizedBox(height: 20),
                // Resend code
                TextButton(
                  onPressed: _isLoading ? null : resendCode,
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

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.post(
        '/auth/verify',
        data: {
          'email': widget.email,
          'code': codeController.text,
        },
      );

      setState(() => _isLoading = false);

      if (response['success']) {
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
        DialogService.showError(
          context,
          message: response['message'] ?? 'Doğrulama başarısız!',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      DialogService.showError(
        context,
        message: 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.',
      );
    }
  }

  Future<void> resendCode() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.resendVerificationCode(widget.email);

      setState(() => _isLoading = false);

      DialogService.showSuccess(
        context,
        message: response['message'] ?? 'Doğrulama kodu yeniden gönderildi!',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      DialogService.showError(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}