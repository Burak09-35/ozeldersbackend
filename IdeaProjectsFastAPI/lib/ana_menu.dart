import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ders_provider.dart';
import 'ozel_ders_takvimi.dart';
import 'ogrenci_listesi_sayfasi.dart';

class AnaMenu extends StatefulWidget {
  const AnaMenu({super.key});

  @override
  State<AnaMenu> createState() => _AnaMenuState();
}

class _AnaMenuState extends State<AnaMenu> {
  String userName = "";

  @override
  void initState() {
    super.initState();

    // 1. Sayfa açılır açılmaz veritabanından dersleri çekmesini istiyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DersProvider>(context, listen: false).dersleriYukle();
    });

    // 2. Kullanıcının adını Shared Preferences'tan alıp ekrana yazdıralım
    _kullaniciBilgileriniGetir();
  }

  void _kullaniciBilgileriniGetir() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "Kullanıcı";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Hoş geldin, $userName"), // Artık ismin burada görünecek!
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _menuButon(context, "Takvim Görünümü", Icons.calendar_today, Colors.indigo, OzelDersTakvimi()),
            const SizedBox(height: 20),
            _menuButon(context, "Öğrenci Bazlı Liste", Icons.people, Colors.orange, const OgrenciListesiSayfasi()),
          ],
        ),
      ),
    );
  }

  Widget _menuButon(BuildContext context, String baslik, IconData ikon, Color renk, Widget sayfa) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: renk,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: renk.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(ikon, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}