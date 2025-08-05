import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:lapor_pungli/utils/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // FUNGSI  Untuk mengupdate data pengguna di Firestore, termasuk email dan created_at
  // (Menggantikan _updateUserLastActive)
  Future<void> _updateUserFirestoreData(User user) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Siapkan data yang akan diupdate/ditambah
      final Map<String, dynamic> dataToUpdate = {
        'lastActiveAt': FieldValue.serverTimestamp(), // Selalu update lastActiveAt
      };

      // Tambahkan email dari Firebase Auth. Pastikan ini disimpan di Firestore.
      if (user.email != null) {
        dataToUpdate['email'] = user.email;
      }

      // Periksa apakah 'created_at' sudah ada di dokumen. Jika belum, tambahkan.
      // Ini penting agar 'created_at' hanya diset sekali saat registrasi/login pertama
      // dan digunakan untuk statistik "Pengguna Baru" di dashboard.
      final docSnapshot = await userDocRef.get();
      if (!docSnapshot.exists || !docSnapshot.data()!.containsKey('created_at')) {
        dataToUpdate['created_at'] = FieldValue.serverTimestamp();
      }

      await userDocRef.set(
        dataToUpdate,
        SetOptions(merge: true), // Gunakan merge: true agar hanya field ini yang diupdate/ditambah
      );
      log('User Firestore data updated: email=${user.email}, lastActiveAt updated, created_at checked/set.');
    } catch (e) {
      log('Error updating user Firestore data for ${user.uid}: $e');
    }
  }

  Future<void> login(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      log("Login berhasil: ${userCredential.user?.email}");

      // Panggil fungsi _updateUserFirestoreData setelah login berhasil
      if (userCredential.user != null) {
        await _updateUserFirestoreData(userCredential.user!); // Teruskan objek User
      }

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Login Berhasil')),
        );
        navigateToHome(context);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        if (e.code == 'user-not-found') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Pengguna tidak ditemukan')),
          );
        } else if (e.code == 'wrong-password') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Password salah')),
          );
        } else if (e.code == 'invalid-email') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Email tidak valid')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Akun tidak ditemukan')),
          );
        }
      }
    } catch (e) {
      log("Error saat login: $e");
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void navigateToHome(BuildContext context) {
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/home');
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Masuk Sebagai Pelapor',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
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
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot_password');
                    },
                    child: Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(color: Color(0xffFDDB3A)),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Masuk',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'Daftar',
                        style: TextStyle(color: Color(0xffFDDB3A)),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}