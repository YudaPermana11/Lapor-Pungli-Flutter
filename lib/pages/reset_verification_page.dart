import 'package:flutter/material.dart';
import 'package:lapor_pungli/utils/app_colors.dart';

class ResetVerificationPage extends StatelessWidget {
  const ResetVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul halaman
              Text(
                'Tautan Reset Kata Sandi Telah Dikirim!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Deskripsi informasi
              Text(
                'Kami telah mengirimkan tautan pengaturan ulang kata sandi ke email Anda. Silakan periksa kotak masuk atau folder spam Anda. Setelah kata sandi berhasil diatur ulang, klik tombol di bawah untuk login ulang ke akun Anda.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 20),
              // Tombol Login Ulang
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigasi kembali ke halaman login
                    Navigator.popUntil(
                        context, ModalRoute.withName('/login'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Login Ulang',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
