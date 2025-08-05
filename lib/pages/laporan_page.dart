import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Tambahkan ini untuk Completer
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:lapor_pungli/utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:developer'; // Import for log

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController judulController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  final TextEditingController jenisController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  String? buktiPendukungPath;
  String? fileType;
  DateTime? selectedDate;

  // Variabel baru untuk indikator unggah dan status unggah
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _uploadErrorMessage = '';

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mp3'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        buktiPendukungPath = result.files.single.path;
        fileType = result.files.single.extension;
        _uploadErrorMessage = ''; // Clear any previous error messages
      });
    }
  }

  void _removeFile() {
    setState(() {
      buktiPendukungPath = null;
      fileType = null;
      _uploadProgress = 0.0; // Reset progress when file is removed
      _uploadErrorMessage = ''; // Clear error message
    });
  }

  Future<String?> uploadToCloudinary(String filePath) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadErrorMessage = ''; // Clear any previous error messages
    });

    try {
      final cloudName = 'djo9px7es';
      final cloudinaryUrl =
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      final uploadPreset = 'laporan_user_preset';

      final file = File(filePath);
      final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));

      final response = await request.send();

      final completer = Completer<String?>();

      final List<int> downloadedBytes = [];
      int receivedBytes = 0;
      
      response.stream.listen(
        (List<int> chunk) {
          downloadedBytes.addAll(chunk);
          receivedBytes += chunk.length;
          
          final String? contentLengthHeader = response.headers['content-length'];
          if (contentLengthHeader != null) {
            final int totalResponseBytes = int.parse(contentLengthHeader);
            setState(() {
              _uploadProgress = receivedBytes / totalResponseBytes;
            });
          }
        },
        onDone: () {
          final String responseBody = utf8.decode(downloadedBytes);
          
          setState(() {
            _uploadProgress = 1.0; 
          });

          if (response.statusCode == 200) {
            final jsonResponse = json.decode(responseBody);
            completer.complete(jsonResponse['secure_url']);
          } else {

            // Tampilkan error mentah dari Cloudinary di SnackBar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ERROR CLOUDINARY (RAW): $responseBody',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: Colors.red[700],
                  duration: Duration(seconds: 10), // Durasi lebih lama agar bisa dibaca
                ),
              );
            }


            final errorBody = json.decode(responseBody);
            String errorMessage = 'Gagal mengunggah file. Silakan coba lagi.';
            if (errorBody != null && errorBody['error'] != null) {
              final errorDetails = errorBody['error'];
              if (errorDetails['message'] != null) {
                errorMessage = 'Gagal mengunggah: ${errorDetails['message']}';
                if (errorDetails['message']
                    .contains('file size too large')) {
                  errorMessage =
                      'Ukuran file terlalu besar. Silakan kompres atau pilih file lain.';
                } else if (errorDetails['message']
                    .contains('Invalid image file')) {
                  errorMessage =
                      'Format file tidak didukung. Mohon unggah gambar atau video yang valid.';
                } else if (errorDetails['message']
                    .contains('Invalid API key')) {
                  errorMessage =
                      'Konfigurasi Cloudinary tidak valid. Mohon periksa kembali.';
                } else if (errorDetails['message'].contains('unknown format')) {
                  errorMessage = 'Format file tidak dikenali. Mohon unggah file audio/video/gambar yang standar.';
                }
              }
            }
            log("Gagal mengunggah file ke Cloudinary: $responseBody");
            setState(() {
              _uploadErrorMessage = errorMessage;
            });
            completer.complete(null);
          }
        },
        onError: (e) {
          log("Error saat mengunggah ke Cloudinary: $e");
          setState(() {
            _uploadErrorMessage =
                'Terjadi kesalahan jaringan atau server. Mohon coba lagi.';
            _uploadProgress = 0.0; // Reset progress on error
          });
          completer.complete(null);
        },
      );
      return completer.future;

    } catch (e) {
      log("Error saat mengunggah ke Cloudinary: $e");
      setState(() {
        _uploadErrorMessage = 'Terjadi kesalahan tak terduga. Mohon coba lagi.';
      });
      return null;
    } finally {
      // Pastikan _isUploading diatur kembali ke false setelah proses selesai (berhasil/gagal)
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _displaySelectedFile() {
    if (buktiPendukungPath == null) {
      return const SizedBox.shrink();
    } else if (['jpg', 'jpeg', 'png'].contains(fileType)) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Image.file(
              File(buktiPendukungPath!),
              height: 100,
            ),
          ),
          Positioned(
            top: 5,
            right: -10,
            child: IconButton(
              onPressed: _removeFile,
              icon: const Icon(Icons.close, color: Colors.white),
              splashRadius: 20,
            ),
          ),
        ],
      );
    } else if (['mp3', 'mp4'].contains(fileType)) {
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Icon(
              fileType == 'mp3' ? Icons.audiotrack : Icons.videocam,
              color: Colors.white,
              size: 50,
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: _removeFile,
              icon: const Icon(Icons.close, color: Colors.red),
              splashRadius: 20,
            ),
          ),
        ],
      );
    } else {
      return const Text(
        'File tidak dikenali',
        style: TextStyle(color: Colors.white),
      );
    }
  }

  Future<void> _saveLaporan() async {
    // Validasi input wajib
    if (judulController.text.trim().isEmpty ||
        deskripsiController.text.trim().isEmpty ||
        jenisController.text.trim().isEmpty ||
        lokasiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon lengkapi semua data terlebih dahulu.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap login terlebih dahulu.')),
      );
      return;
    }

    // Tampilkan indikator loading saat proses penyimpanan (termasuk unggah)
    showDialog(
      context: context,
      barrierDismissible: false, // User must not dismiss it
      builder: (context) => const AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.buttonYellow),
            SizedBox(height: 16),
            Text(
              'Mengirim laporan...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          Navigator.pop(context); // Dismiss loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data pengguna tidak ditemukan.')),
          );
        }
        return;
      }

      final userData = userDoc.data();

      String? downloadURL;
      if (buktiPendukungPath != null) {
        // Panggil fungsi unggah ke Cloudinary
        downloadURL = await uploadToCloudinary(buktiPendukungPath!);
        // Penanganan _isUploading di dalam finally uploadToCloudinary
        // jadi tidak perlu await Future.delayed(Duration(milliseconds: 200)); di sini.

        if (downloadURL == null) {
          // Jika unggah gagal, hentikan proses dan tampilkan error
          if (mounted) {
            Navigator.pop(context); // Dismiss loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(_uploadErrorMessage.isNotEmpty
                      ? _uploadErrorMessage
                      : 'Gagal mengunggah bukti pendukung.')),
            );
          }
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('laporan')
          .doc(user.uid)
          .collection('user_laporan')
          .add({
        'judul': judulController.text.trim(),
        'deskripsi': deskripsiController.text.trim(),
        'jenis': jenisController.text.trim(),
        'lokasi_kejadian': lokasiController.text.trim(),
        'tanggal_kejadian':
            selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
        'bukti_pendukung': downloadURL ?? '',
        'nama_pelapor': userData?['name'] ?? 'Anonim',
        'nomor_kontak': userData?['phone_number'] ?? 'Tidak tersedia',
        'created_at': Timestamp.now(),
        'status': 'Laporan telah dibuat',
      });

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim.')),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim laporan: $e')),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Center(
            child: Text(
              'Konfirmasi Laporan',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Sudah yakin dengan laporannya?',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Periksa kembali',
                style: TextStyle(color: Colors.yellow),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveLaporan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Kirim',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
          'Buat Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peringatan: Laporkan hanya pungutan liar yang nyata. Laporan palsu akan ditindaklanjuti dan dapat berakibat pada sanksi akademik atau pembekuan akun.',
              style: TextStyle(
                color: Colors.redAccent, // Warna merah untuk peringatan
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // Pusatkan teks
            ),
            const SizedBox(height: 15),
            // Panduan
            const Text(
              'Panduan Membuat Laporan Pungli Akademik:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Isi semua kolom dengan informasi yang akurat dan sejelas mungkin.\n'
              '2. Gunakan judul yang singkat namun deskriptif.\n'
              '3. Jelaskan kronologi kejadian secara detail: siapa pelakunya (jika tahu), kapan, di mana, dan berapa nominal pungutan.\n'
              '4. Lampirkan bukti pendukung (ukuran file maks 5MB) jika ada untuk memperkuat laporan Anda.\n'
              '5. Data Anda akan dijaga kerahasiaannya. Laporan ini bertujuan untuk menciptakan lingkungan akademik yang bersih di UPI Kampus Purwakarta.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20), // Spasi antara panduan dan judul form
      

            const Text(
              'Buat Laporan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: judulController,
              decoration: InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: Pungutan Biaya Jilid Skripsi di Luar Ketentuan', // Hint Text
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey[600]), // Style untuk hint text
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deskripsiController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Deskripsi Kejadian',
                hintText: 'Jelaskan detail kejadian: Siapa pelakunya (jika tahu), kapan, di mana lokasi spesifik di kampus, dan berapa nominal pungutan. Contoh: Saya diminta uang Rp 20.000 oleh oknum staf di bagian akademik untuk cap legalisir transkrip, padahal seharusnya gratis.', // Hint Text
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jenisController,
              decoration: InputDecoration(
                labelText: 'Jenis Pungutan Liar',
                hintText: 'Contoh: Pungutan liar terkait administrasi kemahasiswaan. Misal: Pungli uang praktikum/modul, biaya KKN/PPL tidak resmi, uang tanda tangan dosen/pembimbing.', // Hint Text
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lokasiController,
              decoration: InputDecoration(
                labelText: 'Lokasi Kejadian',
                hintText: 'Contoh: Gedung FPMIPA, Ruang Tata Usaha, Lantai 1. Atau: Area parkir belakang Gedung FPBS.', // Hint Text
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? 'Tanggal: ${DateFormat('dd-MM-yyyy').format(selectedDate!)}'
                        : 'Tanggal belum dipilih',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonYellow,
                  ),
                  child: const Text('Pilih Tanggal',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bukti Pendukung',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukan bukti pendukung seperti foto (maks 5MB)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonYellow,
                    ),
                    child: const Text(
                      'Pilih File',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  _displaySelectedFile(),
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.buttonYellow),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mengunggah: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                  if (_uploadErrorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _uploadErrorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showConfirmationDialog,
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