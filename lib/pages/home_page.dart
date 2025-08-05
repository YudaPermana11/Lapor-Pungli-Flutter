import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapor_pungli/components/custom_navbar.dart';
import 'package:lapor_pungli/utils/app_colors.dart';
// import 'package:lapor_pungli/pages/notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  String? profileImageUrl;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _currentStep = 0; // State ini akan dikontrol oleh tap ikon

  final List<Map<String, String>> _steps = [
    {
      'title': 'Ceritakan kronologi kejadian',
      'description':
          'Cerita Anda sangat penting agar kami dapat memahami kejadian dengan jelas dan membantu menyelesaikan pengaduan Anda. Informasi yang akurat dan rinci akan mempermudah proses tindak lanjut.'
    },
    {
      'title': 'Unggah bukti laporan',
      'description':
          'Bukti yang Anda lampirkan sangat membantu untuk memperkuat laporan Anda. Foto atau dokumen yang relevan akan memberikan bukti yang kuat untuk mendukung pengaduan dan mempercepat penyelesaian kasus.'
    },
    {
      'title': 'Periksa kembali laporan',
      'description':
          'Memeriksa kembali laporan Anda adalah langkah penting untuk memastikan semua informasi sudah lengkap dan benar. Hal ini akan membantu kami menangani laporan dengan cepat dan efektif. Pastikan laporan Anda sudah benar.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _autoSlide(); // Ambil nama pengguna dari Firestore
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          userName = doc['name'] ?? 'Nama pengguna';
          profileImageUrl = doc['profile_image'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Nama pengguna';
        profileImageUrl = '';
      });
    }
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
        _autoSlide();
      }
    });
  }

  // Fungsi _nextStep sekarang hanya untuk tombol "Next" di bagian panduan dinamis
  // Ini akan mengubah langkah ke depan, tapi tidak mengreset ke 0
  void _nextStep() {
    setState(() {
      // Hanya maju jika tidak di langkah terakhir
      if (_currentStep < _steps.length - 1) { // MODIFIKASI: Gunakan _steps.length
        _currentStep++;
      } else {
        // Jika sudah di langkah terakhir, kembali ke langkah 0
        _currentStep = 0; 
      }
    });
  }

  // Fungsi baru untuk menangani tap pada ikon
  void _onIconTap(int index) {
    setState(() {
      _currentStep = index; // Set _currentStep sesuai index ikon yang di-tap
    });
  }

  void _onNavbarTap(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, '/riwayat_laporan');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 1,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[400],
                              backgroundImage: (profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty)
                                  ? NetworkImage(profileImageUrl!)
                                  : null,
                              child:
                                  (profileImageUrl == null || profileImageUrl!.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 30,
                                          color: Colors.white,
                                        )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName ?? 'Nama pengguna',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15, // Disesuaikan dari diskusi sebelumnya
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const Text(
                                    'Mahasiswa UPI Purwakarta',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('userId', isEqualTo: user?.uid)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData) {
                        return IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        );
                      }

                      final unseenCount = snapshot.data!.docs.length;

                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications,
                              color: unseenCount > 0 ? AppColors.buttonYellow : Colors.white,),
                            onPressed: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                          ),
                          if (unseenCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unseenCount > 9 ? '9+' : unseenCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 20),
              // Slider untuk gambar
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    Image.asset('assets/images/slide 1.jpeg', fit: BoxFit.cover),
                    Image.asset('assets/images/slide 2.png', fit: BoxFit.cover),
                    Image.asset('assets/images/slide 3.jpg', fit: BoxFit.cover),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Indikator slider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: _currentPage == index ? 16.0 : 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.buttonYellow
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),
              // Fungsionalitas klik pada ikon
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Ikon "Buat Laporan"
                    _buildIconColumn(
                      icon: Icons.edit,
                      label: 'Laporkan',
                      index: 0,
                    ),
                    // Ikon "Bukti Laporan"
                    _buildIconColumn(
                      icon: Icons.image,
                      label: 'Unggah Bukti',
                      index: 1,
                    ),
                    // Ikon "Pratinjau Laporan"
                    _buildIconColumn(
                      icon: Icons.preview,
                      label: 'Pratinjau',
                      index: 2,
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 20),
              // Container yang menjelaskan langkah-langkah
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _steps[_currentStep]['title']!, // Teks judul dinamis
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _steps[_currentStep]['description']!, // Teks deskripsi dinamis
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _nextStep, // Tombol ini tetap ada untuk maju secara berurutan
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(_currentStep < (_steps.length - 1) ? 'Next' : 'OK'), // Teks tombol dinamis
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              //Tombol Buat Laporan utama di bagian bawah
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/buat_laporan');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "Buat Laporan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: 0,
        onTap: _onNavbarTap,
      ),
    );
  }

  // Widget pembantu untuk membangun kolom ikon 
  Widget _buildIconColumn({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return InkWell( // Menggunakan InkWell agar bisa diklik dan ada feedback visual
      onTap: () => _onIconTap(index), // Memanggil fungsi baru saat di-tap
      borderRadius: BorderRadius.circular(8), // Border radius untuk efek tap
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Memberikan padding internal agar area tap lebih nyaman
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: _currentStep == index // Warna ikon berdasarkan _currentStep
                  ? AppColors.buttonYellow
                  : Colors.grey,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: _currentStep == index // Warna teks label berdasarkan _currentStep
                    ? AppColors.buttonYellow
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}