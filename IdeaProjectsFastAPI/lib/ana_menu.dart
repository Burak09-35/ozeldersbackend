import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ders_provider.dart';

// Taze böldüğümüz ve ismini güncellediğimiz sayfaları içe aktarıyoruz
import 'ogretmen_takvimi.dart';
import 'ogrenci_takvimi.dart';
import 'ogrenci_listesi_sayfasi.dart';

class AnaMenu extends StatefulWidget {
  const AnaMenu({super.key});

  @override
  State<AnaMenu> createState() => _AnaMenuState();
}

class _AnaMenuState extends State<AnaMenu> {
  String userName = "";
  String userRole = "öğrenci"; // Güvenlik için varsayılan rol öğrenci

  @override
  void initState() {
    super.initState();

    // 1. Sayfa açılır açılmaz veritabanından dersleri çekmesini istiyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DersProvider>(context, listen: false).dersleriYukle();
    });

    // 2. Kullanıcının adını ve rolünü Shared Preferences'tan alalım
    _kullaniciBilgileriniGetir();
  }

  void _kullaniciBilgileriniGetir() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "Kullanıcı";
      // Rol bilgisini hafızadan çekiyoruz, kayıt ekranında bunu set etmemiz gerekecek
      userRole = prefs.getString('user_role') ?? "öğrenci";
    });
  }

  @override
  Widget build(BuildContext context) {

    // --- KAVŞAK MANTIĞI (ROUTER) ---
    // Kullanıcının rolüne göre gideceği takvim sayfasını önceden belirliyoruz.
    Widget gidecegiTakvimSayfasi = (userRole == "öğretmen")
        ? OgretmenTakvimi()
        : const OgrenciTakvimi();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Hoş geldin, $userName"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 1. TAKVİM BUTONU (Herkes görür ama herkes farklı yere gider)
            _menuButon(
                context,
                "Ders Programım",
                Icons.calendar_today,
                Colors.indigo,
                gidecegiTakvimSayfasi // Kavşak değişkenimizi buraya verdik
            ),

            const SizedBox(height: 20),

            // 2. ÖĞRENCİ LİSTESİ BUTONU (Sadece Öğretmenler Görür)
            // Dart dilindeki bu efsanevi 'if' kullanımı sayesinde widget'ı tamamen gizliyoruz
            if (userRole == "öğretmen")
              _menuButon(
                  context,
                  "Öğrencilerim",
                  Icons.people,
                  Colors.orange,
                  const OgrenciListesiSayfasi()
              ),
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