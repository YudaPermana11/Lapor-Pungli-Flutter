import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapor_pungli/components/custom_navbar.dart';
import 'package:lapor_pungli/pages/detail_laporan_page.dart';
import 'package:lapor_pungli/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LaporanSayaPage extends StatelessWidget {
  const LaporanSayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true, // Untuk memindahkan judul ke tengah
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laporan') // Root collection
            .doc(FirebaseAuth.instance.currentUser!.uid) // User ID
            .collection('user_laporan') // Sub-collection
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Anda belum membuat laporan',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final laporanData = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: laporanData.length,
            itemBuilder: (context, index) {
              final laporan = laporanData[index];
              final judul = laporan['judul'] ?? 'Tidak ada judul';
              final status =
                  (laporan.data() as Map<String, dynamic>).containsKey('status')
                      ? laporan['status']
                      : 'Laporan telah dibuat'; // Default jika status tidak ada
              final createdAt = laporan['created_at']?.toDate();
              final formattedDate = createdAt != null
                  ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                  : 'Tidak diketahui';

              // === Logika Warna Status (MODIFIKASI DIMULAI DI SINI) ===
              Color statusColor;
              if (status == 'Selesai') {
                statusColor = Colors.green; // Warna hijau untuk Selesai
              } else if (status == 'Diproses') {
                statusColor = Colors.yellow; // Warna kuning untuk Diproses
              } else if (status == 'Laporan telah dibuat') {
                statusColor = Colors.grey; // Warna oranye/amber untuk Laporan telah dibuat
              } else if (status == 'Tidak Diproses') {
                statusColor = AppColors.buttonRed; // <<< Menggunakan AppColors.buttonRed
              } else {
                statusColor = Colors.grey; // Default warna jika status tidak dikenal
              }
              // === Logika Warna Status (MODIFIKASI BERAKHIR DI SINI) ===

              return Card(
                color: AppColors.backgroundLight,
                shadowColor: Colors.black.withAlpha(51),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey, // Background for image/icon
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: laporan['bukti_pendukung'] != null && laporan['bukti_pendukung'].isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  laporan['bukti_pendukung'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, color: Colors.white), // Handle image load error
                                ),
                              )
                            : const Icon(Icons.image, color: Colors.white), // Default icon if no image
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              judul,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 8),
                              decoration: BoxDecoration(
                                color: statusColor, // <<< Menggunakan statusColor yang sudah ditentukan
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.black, // Teks status biasanya hitam agar kontras dengan latar
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Navigasi ke halaman detail laporan
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailLaporanPage(
                                    laporanId: laporan.id,
                                    userId: FirebaseAuth.instance.currentUser!.uid,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Lihat',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 1, // Laporan Saya index
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}