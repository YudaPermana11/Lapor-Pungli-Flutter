import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

/// Fungsi untuk mengunggah file ke Cloudinary.
/// [filePath] adalah path file yang akan diunggah.
/// [userId] adalah ID pengguna untuk membuat folder khusus di Cloudinary.
Future<String?> uploadToCloudinary(String filePath, String userId) async {
  final cloudName = 'djo9px7es'; // Ganti dengan Cloud Name Anda
  final uploadPreset = 'laporan_user_preset'; // Nama Upload Preset
  final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Periksa apakah filePath kosong
  if (filePath.isEmpty) {
    log('File path kosong. Upload dibatalkan.');
    return null;
  }

  try {
    // Buat request untuk unggahan
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.fields['upload_preset'] = uploadPreset; // Upload preset dari Cloudinary
    request.fields['folder'] = 'laporan_user/$userId'; // Folder berdasarkan userId
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // Kirim request
    log('Mengirim permintaan unggah ke Cloudinary...');
    final response = await request.send();

    // Periksa respons
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      log('Upload berhasil: $responseBody');
      final decodedJson = json.decode(responseBody);
      return decodedJson['secure_url'] as String?;
    } else {
      final responseBody = await response.stream.bytesToString();
      log('Upload gagal: Status ${response.statusCode}, Body: $responseBody');
      return null;
    }
  } catch (e) {
    // Tangkap semua kesalahan
    log('Terjadi kesalahan saat mengunggah: $e');
    return null;
  }
}
