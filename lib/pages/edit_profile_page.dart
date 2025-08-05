import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapor_pungli/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nimController = TextEditingController(); // <<< Tambahkan ini untuk NIM
  String? profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Jangan lupa untuk dispose controller saat State di dispose
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    nimController.dispose(); // <<< Tambahkan dispose untuk nimController
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            nameController.text = data?['name'] ?? '';
            emailController.text = user.email ?? '';
            phoneController.text = data?['phone_number'] ?? '';
            nimController.text = data?['nim'] ?? ''; // <<< Baca NIM dari Firestore
            profileImageUrl = data?['profile_image'] ?? '';
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data pengguna tidak ditemukan.')),
            );
          }
        }
      } catch (e) {
        log('Error loading user data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat data pengguna: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': nameController.text.trim(),
          'phone_number': phoneController.text.trim(),
          'nim': nimController.text.trim(), // <<< Simpan NIM ke Firestore
          'profile_image': profileImageUrl ?? '',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui profil: $e')),
          );
        }
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      log('User canceled image picking');
      return;
    }

    String? uploadedUrl = await _uploadToCloudinary(pickedFile.path);
    if (uploadedUrl != null) {
      if (mounted) {
        setState(() {
          profileImageUrl = uploadedUrl;
        });
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profile_image': uploadedUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah foto profil')),
        );
      }
    }
  }

  Future<String?> _uploadToCloudinary(String filePath) async {
    final cloudName = 'djo9px7es';
    final uploadPreset = 'laporan_user_preset';
    final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedJson = json.decode(responseBody);
        return decodedJson['secure_url'];
      } else {
        log('Cloudinary upload failed: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      log('Error uploading to Cloudinary: $e');
      return null;
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
          'Edit Profil',
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
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[400],
              backgroundImage:
                  profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? NetworkImage(profileImageUrl!)
                      : null,
              child: profileImageUrl == null || profileImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _changeProfilePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Ganti Foto',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20), 
            TextField(
              controller: nimController, // Menggunakan nimController
              decoration: InputDecoration(
                labelText: 'NIM', // Label untuk NIM
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number, // NIM biasanya angka
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Nomor Handphone',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            // MODIFIKASI DIMULAI DI SINI UNTUK NIM
            const SizedBox(height: 30), // Jarak setelah NIM TextField
            // MODIFIKASI BERAKHIR DI SINI UNTUK NIM
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}