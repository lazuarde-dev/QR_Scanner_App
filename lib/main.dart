import 'package:flutter/material.dart';
import 'package:qr_scanner_app/views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Color maroonColor = Color(0xff9E3B3B);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'QR Scanner',
          debugShowCheckedModeBanner: false,

          // --- KONFIGURASI TEMA ---
          themeMode: currentMode, // Mengikuti status notifier
          // A. TEMA TERANG (LIGHT)
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: maroonColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: maroonColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // B. TEMA GELAP (DARK)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Color(0xFF121212), // Hitam pekat
            primaryColor: maroonColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: maroonColor,
              brightness: Brightness.dark,
              surface: Color(0xFF1E1E1E), // Warna kartu di mode gelap
            ),
            useMaterial3: true,
          ),

          home: SplashScreen(),
        );
      },
    );
  }
}
