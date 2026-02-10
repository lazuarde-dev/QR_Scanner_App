import 'package:flutter/material.dart';
import 'package:qr_scanner_app/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  void _startApp() async {
    // Jeda 3 detik untuk memberikan kesan premium
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Palette Warna (Sesuai dengan Login & Register)
  final Color deepGreen = const Color(0xFF1B4332);
  final Color softPink = const Color(0xFFFFD1DC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan Hijau Tua sebagai latar belakang utama agar terlihat elegan
      backgroundColor: deepGreen,
      body: Stack(
        children: [
          // Aksen Dekoratif Minimalis (Opsional: Lingkaran Pink halus di pojok)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: softPink.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon dengan container bulat pink halus
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: softPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 80,
                    color: softPink, // Icon menggunakan warna pink agar kontras
                  ),
                ),
                const SizedBox(height: 24),
                
                // Teks Judul Minimalis
                Text(
                  "TICKETSCAN",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8, // Memberikan jarak antar huruf agar estetik
                    color: softPink.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Indikator Loading Kecil di bawah
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(softPink.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}