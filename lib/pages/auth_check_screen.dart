// lib/pages/auth_check_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapor_pungli/utils/app_colors.dart'; // Import warna aplikasi Anda
import 'package:lapor_pungli/pages/home_page.dart';
import 'package:lapor_pungli/pages/login_page.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    // Gunakan Future.delayed untuk memberikan waktu melihat splash screen
    // dan juga menunggu stream authStateChanges menghasilkan nilai awal
    Future.delayed(const Duration(seconds: 2), () { // Durasi bisa disesuaikan
      _checkAuthStatus();
    });
  }

  void _checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) { // Pastikan widget masih di tree sebelum navigasi
        if (user == null) {
          // Pengguna belum login, arahkan ke halaman login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          // Pengguna sudah login, arahkan ke halaman home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark, // Warna latar belakang splash screen Anda
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi (sesuaikan dengan logo Anda yang sebenarnya)
            // Anda bisa menggunakan Image.asset atau Image.network
            Image.asset(
              'assets/images/SplashScreen.png', // Menggunakan gambar splash screen yang sudah Anda buat
              // width: 200, // Sesuaikan ukuran
              // height: 200, // Sesuaikan ukuran
              width: MediaQuery.of(context).size.width * 0.5, // 50% dari lebar layar
              height: MediaQuery.of(context).size.width * 0.5
            ),
            // const SizedBox(height: 20),
            // Text(
            //   'Lapor Pungli',
            //   style: TextStyle(
            //     color: AppColors.textYeLight, // Warna teks judul Anda
            //     fontSize: 28,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 10),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonYellow), // Warna loading indicator
            ),
            // const SizedBox(height: 10),
            // Text(
            //   'Memuat aplikasi...',
            //   style: TextStyle(
            //     color: AppColors.textGrey, // Warna teks loading
            //     fontSize: 16,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}