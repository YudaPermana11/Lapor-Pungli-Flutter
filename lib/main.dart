import 'package:flutter/material.dart';
import 'package:lapor_pungli/pages/detail_laporan_page.dart';
import 'package:lapor_pungli/pages/edit_profile_page.dart';
import 'package:lapor_pungli/pages/forgot_password_page.dart';
import 'package:lapor_pungli/pages/history_page.dart';
import 'package:lapor_pungli/pages/home_page.dart';
import 'package:lapor_pungli/pages/laporan_page.dart';
import 'package:lapor_pungli/pages/new_password_page.dart';
import 'package:lapor_pungli/pages/profile_page.dart';
import 'package:lapor_pungli/pages/register_page.dart';
import 'package:lapor_pungli/pages/reset_verification_page.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:lapor_pungli/utils/app_colors.dart';
import 'package:lapor_pungli/pages/notification_page.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // <<< TAMBAHKAN INI
import 'package:lapor_pungli/pages/auth_check_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Pelaporan Pungli',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
        ),
      ),
      home: const AuthCheckScreen(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/reset_verification': (context) => ResetVerificationPage(),
        '/home': (context) => HomePage(),
        '/riwayat_laporan': (context) => LaporanSayaPage(),
        '/profile': (context) => ProfilePage(),
        '/edit_profile': (context) => EditProfilePage(),
        '/ganti_kata_sandi': (context) => ChangePasswordPage(),
        '/buat_laporan': (context) => LaporanPage(),
        '/notifications': (context) => NotificationPage(),
        // '/detail_laporan': (context) => DetailLaporanPage(laporanId: '', userId: '',),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail_laporan') {
          final args = settings.arguments;
          if (args is Map<String, dynamic> && args.containsKey('userId') && args.containsKey('laporanId')) {
            final userId = args['userId'] as String;
            final laporanId = args['laporanId'] as String;
            return MaterialPageRoute(
              builder: (_) => DetailLaporanPage(
                userId: userId,
                laporanId: laporanId,
              ),
            );
          }
          // Jika args tidak sesuai, bisa arahkan ke halaman error atau return null
          return MaterialPageRoute(builder: (_) => Scaffold(
            body: Center(child: Text('Argument invalid untuk halaman detail laporan')),
          ));
        }
        return null;
      },
    );
  }
}
