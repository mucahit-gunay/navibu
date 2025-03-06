import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:navibuapp/utils/device_utility.dart';
import 'package:navibuapp/utils/helpers.dart';
import 'package:navibuapp/utils/animation_loader.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isLoading = false;
  bool codeSent = false;
  String message = '';

  Future<void> sendResetCode() async {
    TDeviceUtils.hideKeyboard(context);
    
    if (emailController.text.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TAnimationLoader.error(width: 100, height: 100),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'E-posta adresi boş bırakılamaz',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      setState(() {
        message = "Geçerli bir e-posta adresi giriniz";
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Bağlantı zaman aşımına uğradı');
        },
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          codeSent = true;
          message = 'Doğrulama kodu e-posta adresinize gönderildi.';
        });
        
        // Show success animation
        await showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TAnimationLoader.success(width: 100, height: 100),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Doğrulama kodu e-posta adresinize gönderildi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          message = data['error'] ?? 'Bir hata oluştu.';
        });
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        message = 'Sunucu yanıt vermedi. Lütfen tekrar deneyin.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        message = 'Bağlantı hatası: Lütfen internet bağlantınızı kontrol edin';
      });
    }
  }

  Future<void> resetPassword() async {
    if (codeController.text.isEmpty || newPasswordController.text.isEmpty) {
      THelperFunctions.showAlert(
        context,
        'Uyarı',
        'Lütfen tüm alanları doldurunuz.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'code': codeController.text.trim(),
          'new_password': newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        await showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TAnimationLoader.success(width: 100, height: 100),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Şifreniz başarıyla güncellendi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Şifre sıfırlama başarısız');
      }
    } catch (e) {
      if (!mounted) return;
      THelperFunctions.showAlert(
        context,
        'Hata',
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            if (!codeSent) ...[
              const Text(
                'Şifrenizi sıfırlamak için e-posta adresinizi girin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : sendResetCode,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Doğrulama Kodu Gönder'),
              ),
            ] else ...[
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Doğrulama Kodu',
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : resetPassword,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Şifreyi Sıfırla'),
              ),
            ],
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: message.contains('başarıyla') ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }
} 