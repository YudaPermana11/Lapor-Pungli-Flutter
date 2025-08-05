import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan ini untuk Firebase
import 'package:lapor_pungli/utils/app_colors.dart';

class ForgotPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgotPasswordPage({super.key});

  // Fungsi untuk mengirimkan email reset password
  Future<void> sendPasswordResetEmail(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Tautan reset kata sandi telah dikirim ke email Anda.',
          ),
        ),
      );

      // Gunakan WidgetsBinding untuk menunda navigasi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamed(context, '/reset_verification');
        }
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lupa Kata Sandi ?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Masukkan alamat email Anda, dan kami akan membantu Anda mengatur ulang kata sandi dalam beberapa langkah mudah.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => sendPasswordResetEmail(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Kirim Tautan Reset',
                      style: TextStyle(color: Colors.black),
                    ),
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
