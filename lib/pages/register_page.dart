import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapor_pungli/utils/app_colors.dart';
import 'dart:developer';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? selectGender;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    nimController.dispose();
    dateOfBirthController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan data pengguna ke Firestore
  Future<void> saveUserData({
    required String uid,
    required String nim,
    required String name,
    required String dateOfBirth,
    required String gender,
    required String phoneNumber,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'nim': nim,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'phone_number': phoneNumber,
        'created_at': FieldValue.serverTimestamp(),
      });
      log('Data pengguna berhasil disimpan ke Firestore');
    } catch (e) {
      log('Error menyimpan data pengguna: $e');
    }
  }

  Future<void> register(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Validasi dasar
    if (nameController.text.trim().isEmpty ||
        dateOfBirthController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        nimController.text.trim().isEmpty || // <<< VALIDASI NIM
        selectGender == null) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Semua field harus diisi'),
          ),
        );
      }
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak cocok'),
          ),
        );
      }
      return;
    }

    try {
      // Registrasi pengguna menggunakan Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Menyimpan data tambahan pengguna ke Firestore
      await saveUserData(
        uid: userCredential.user!.uid,
        name: nameController.text.trim(),
        nim: nimController.text.trim(),
        dateOfBirth: dateOfBirthController.text.trim(),
        gender: selectGender ?? "Tidak diisi",
        phoneNumber: phoneController.text.trim(),
      );

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil')),
        );
        navigateToHome(context); // Navigasi ke halaman utama
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        if (e.code == 'email-already-in-use') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Email sudah digunakan')),
          );
        } else if (e.code == 'weak-password') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Password terlalu lemah')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void navigateToHome(BuildContext context) {
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Daftar Akun',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Masukkan nama Anda ',
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nimController,
                decoration: InputDecoration(
                  labelText: 'NIM',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Masukkan NIM Anda ',
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                controller: dateOfBirthController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Contoh: 11 Maret 2003',
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Jenis Kelamin',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Radio<String>(
                          value: 'Laki-laki',
                          groupValue: selectGender,
                          onChanged: (value) {
                            setState(() {
                              selectGender = value;
                            });
                          },
                          activeColor: AppColors.buttonYellow,
                          fillColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.buttonYellow;
                            }
                            return Colors.white;
                          },
                        ),
                      ),
                      Text(
                        'Laki-laki',
                        style: TextStyle(color: Colors.white),
                      ),
                      Radio<String>(
                        value: 'Perempuan',
                        groupValue: selectGender,
                        onChanged: (value) {
                          setState(() {
                            selectGender = value;
                          });
                        },
                        activeColor: AppColors.buttonYellow,
                          fillColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.buttonYellow;
                            }
                            return Colors.white;
                          },
                        ),
                      ),
                      Text(
                        'Perempuan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'No. Hp',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Contoh: 08123xxxxxx',
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Contoh: yuda.per321@gmail.com',
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
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
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => register(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffFDDB3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Daftar',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Kembali ke halaman login
                    },
                    child: Text(
                      'Masuk',
                      style: TextStyle(color: AppColors.textYeLight),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
