import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapor_pungli/components/custom_navbar.dart';
import 'package:lapor_pungli/utils/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userName;
  String? userEmail;
  String? userNIM; // <<< Tambahkan state ini untuk NIM
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Ambil data pengguna dari Firestore
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          userName = doc['name'] ?? 'Nama Pengguna';
          userEmail = user.email;
          userNIM = doc['nim'] ?? 'NIM tidak tersedia'; // <<< Ambil NIM dari Firestore
          profileImageUrl = doc['profile_image'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Nama Pengguna';
        userEmail = 'Email tidak ditemukan';
        userNIM = 'NIM tidak tersedia'; // <<< Set fallback untuk NIM jika ada error
        profileImageUrl = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Foto profil
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[400],
              backgroundImage:
                  (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                      ? NetworkImage(profileImageUrl!)
                      : null,
              child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                  ? const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            // Nama
            Text(
              userName ?? 'Nama Pengguna',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // MODIFIKASI DIMULAI DI SINI UNTUK NIM
            // NIM
            Text(
              userNIM ?? 'NIM tidak tersedia', // Menggunakan userNIM
              style: const TextStyle(
                color: Colors.grey, // Warna abu-abu seperti email
                fontSize: 14,
              ),
            ),
            // MODIFIKASI BERAKHIR DI SINI UNTUK NIM
            const SizedBox(height: 8),
            // Email
            Text(
              userEmail ?? 'Email tidak ditemukan',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8), // <<< Tambahkan jarak sebelum NIM

            // Tombol Edit Profil
            ElevatedButton(
              onPressed: () {
                // Tambahkan navigasi ke halaman edit profil di sini
                Navigator.pushNamed(context, '/edit_profile').then((_) {
                  //Refresh saat data kembali dari halaman edit profile
                  _fetchUserData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Edit Profil',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 30),
            // Ganti Kata Sandi
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.lock, color: AppColors.buttonYellow),
                title: const Text(
                  'Ganti Kata Sandi',
                  style: TextStyle(color: Colors.white),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  Navigator.pushNamed(context, '/ganti_kata_sandi');
                },
              ),
            ),
            const SizedBox(height: 10),
            // Tombol Keluar
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 2, // Index untuk halaman profil
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/riwayat_laporan');
          }
        },
      ),
    );
  }
}