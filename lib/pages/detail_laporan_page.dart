import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapor_pungli/utils/app_colors.dart';

class DetailLaporanPage extends StatelessWidget {
  final String laporanId;
  final String userId;

  const DetailLaporanPage({
    super.key,
    required this.laporanId,
    required this.userId,
  });

    static Route route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => DetailLaporanPage(
        userId: args['userId'],
        laporanId: args['laporanId'],
      ),
    );
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
          'Detail Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('laporan')
            .doc(userId)
            .collection('user_laporan')
            .doc(laporanId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Laporan tidak ditemukan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          final laporan = snapshot.data!.data() as Map<String, dynamic>;
          final judul = laporan['judul'] ?? 'Tidak ada judul';
          final deskripsi = laporan['deskripsi'] ?? 'Tidak ada deskripsi';
          final lokasi = laporan['lokasi_kejadian'] ?? 'Lokasi tidak tersedia';
          final tanggalKejadian = laporan['tanggal_kejadian']?.toDate();
          final formattedDate = tanggalKejadian != null
              ? '${tanggalKejadian.day}-${tanggalKejadian.month}-${tanggalKejadian.year}'
              : 'Tidak diketahui';
          final buktiPendukung = laporan['bukti_pendukung'];
          final namaPelapor = laporan['nama_pelapor'] ?? 'Anonim';
          final status = laporan['status'] ?? 'Laporan telah dibuat';

          // === Logika Warna Status 
          Color statusColor;
          if (status == 'Selesai') {
            statusColor = Colors.green;
          } else if (status == 'Diproses') {
            statusColor = Colors.yellow;
          } else if (status == 'Laporan telah dibuat') { // Tambahkan kondisi untuk 'Laporan telah dibuat'
            statusColor = Colors.grey; // warna grey untuk status baru
          } else if (status == 'Tidak Diproses') { // <<< Tambahkan kondisi untuk 'Tidak Diproses'
            statusColor = AppColors.buttonRed; // <<< Menggunakan AppColors.buttonRed
          }
          else {
            statusColor = Colors.grey; // Default warna jika status tidak dikenal
          }
        

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Bukti Pendukung (Gambar)
                buktiPendukung != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          buktiPendukung,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white, size: 50),
                        ),
                      ),

                const SizedBox(height: 20),

                // 📄 Judul
                Text(
                  judul,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔖 Status Laporan
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor, // Menggunakan variabel statusColor yang sudah ditentukan
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                // 📍 Lokasi Kejadian
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lokasi,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // 📅 Tanggal Kejadian
                Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // 👤 Nama Pelapor
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      namaPelapor,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 📝 Deskripsi
                const Text(
                  'Deskripsi Kejadian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  deskripsi,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}