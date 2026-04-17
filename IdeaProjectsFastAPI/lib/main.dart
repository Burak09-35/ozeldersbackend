import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'giris_ekrani.dart';
import 'kayit_ekrani.dart';
import 'ana_menu.dart';
import 'ders_provider.dart';

void main() {
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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E293B),
          secondary: Color(0xFF3B82F6),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: Color(0xFF334155),
        ),

        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFF334155),
          displayColor: const Color(0xFF1E293B),
        ),

        // --- İŞTE SİHİRLİ DOKUNUŞ BURADA ---
        // Tüm projedeki App Barları ferah ve arka planla uyumlu hale getirdik!
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Arka planı şeffaf yaptık
          foregroundColor: Color(0xFF1E293B), // İkonlar ve yazı rengi Antrasit oldu
          elevation: 0, // Ağır gölgeyi kaldırdık
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B), // Başlık rengi Antrasit
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1E293B)), // Geri okları vb. Antrasit
        ),
        // ------------------------------------

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

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 3,
        ),

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

      routes: {
        '/': (context) => const GiriisEkrani(),
        '/kayit': (context) => const KayitEkrani(),
        '/anaMenu': (context) => const AnaMenu(),
      },
    );
  }
}