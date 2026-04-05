import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // YENİ: Yazı tipi paketi eklendi

// Kendi sayfaların
import 'giris_ekrani.dart';
import 'kayit_ekrani.dart';
import 'ana_menu.dart';
import 'ders_provider.dart';

void main() {
  // Firebase.initializeApp kısmını sildik çünkü FastAPI kullanacağız
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DersProvider()),
      ],
      child: const OzelDersUygulamasi(),
    ),
  );
}

class OzelDersUygulamasi extends StatelessWidget {
  const OzelDersUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',

      // --- YENİ PROFESYONEL TEMAMIZ ---
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Göz yormayan arka plan

        // Renk Paleti
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E293B), // Derin Antrasit (Ana Renk)
          secondary: Color(0xFF3B82F6), // Soft Mavi (Vurgu Rengi)
          surface: Colors.white, // Kart ve menü arkaplanları
          onPrimary: Colors.white, // Ana renk üzerindeki yazılar
          onSurface: Color(0xFF334155), // Beyaz üzerindeki yazılar (Koyu Gri)
        ),

        // Tipografi (Poppins)
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFF334155),
          displayColor: const Color(0xFF1E293B),
        ),

        // AppBar (Üst Menü) Tasarımı
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Buton Tasarımı
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ),

        // Floating Action Button Tasarımı (Örn: Ders Ekleme butonu)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 3,
        ),

        // TextField (Girdi Alanı) Tasarımı
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      // ---------------------------------

      routes: {
        '/': (context) => const GiriisEkrani(),
        '/kayit': (context) => const KayitEkrani(),
        '/anaMenu': (context) => const AnaMenu(),
      },
    );
  }
}