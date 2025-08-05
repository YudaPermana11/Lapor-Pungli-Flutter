import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapor_pungli/utils/app_colors.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final user = FirebaseAuth.instance.currentUser;

  String formatDateTime(DateTime dt) {
    // Contoh format: 16 Mei 2025, 14:30
    return "${dt.day} ${_monthName(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifikasi')),
        body: const Center(child: Text('Anda belum login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Tidak ada notifikasi', style: TextStyle(color: Colors.grey, fontSize: 16),));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final docSnap = docs[index];
              final data = docSnap.data()! as Map<String, dynamic>;
              final message = data['message'] ?? '';
              final timestamp = data['timestamp']?.toDate() ?? DateTime.now();
              final isRead = data['isRead'] ?? false;

              return InkWell(
                onTap: () async {
                  // Tandai notifikasi sudah dibaca
                  if (!isRead) {
                    await docSnap.reference.update({'isRead': true});
                  }

                  if (!context.mounted) return;

                  // Navigasi ke detail laporan jika ada laporanId dan userId
                  final laporanId = data['laporanId'];
                  final userId = data['userId'];
                  if (laporanId != null && userId != null) {
                    Navigator.pushNamed(
                      context,
                      '/detail_laporan',
                      arguments: {'userId': userId, 'laporanId': laporanId},
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.transparent
                        : AppColors.buttonYellow.withValues(alpha: 0.1 ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : AppColors.buttonYellow,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? Colors.grey
                                    : AppColors.buttonYellow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                message,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? AppColors.buttonYellow
                                    : AppColors.buttonYellow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formatDateTime(timestamp),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 8),
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.buttonYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.buttonRed),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Notifikasi?'),
                              content: const Text(
                                  'Apakah Anda yakin ingin menghapus notifikasi ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) return;
                          if (confirm == true) {
                            try {
                              await docSnap.reference.delete();

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Notifikasi berhasil dihapus')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Gagal menghapus notifikasi: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
