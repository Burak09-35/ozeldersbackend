import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const GiriisEkrani(),
        '/kayit': (context) => const KayitEkrani(),
        '/anaMenu': (context) => const AnaMenu(),
      },
    );
  }
}