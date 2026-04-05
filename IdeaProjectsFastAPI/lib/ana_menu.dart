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
      userRole = prefs.getString('user_role') ?? "öğrenci";
    });
  }

  // --- ÇIKIŞ YAP FONKSİYONU ---
  void _cikisYap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hafızadaki tüm kullanıcı verilerini sil
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/'); // Giriş ekranına dön
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerine kolay erişim
    final colorScheme = Theme.of(context).colorScheme;

    // --- KAVŞAK MANTIĞI (ROUTER) ---
    Widget gidecegiTakvimSayfasi = (userRole == "öğretmen")
        ? const OgretmenTakvimi()
        : const OgrenciTakvimi();

    return Scaffold(
      // Arka planı main.dart'a bıraktık (scaffoldBackgroundColor)
      appBar: AppBar(
        title: const Text("Özel Ders Asistanı"),
        // Çıkış Yap Butonu
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            onPressed: _cikisYap,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KARŞILAMA MESAJI ---
              Text(
                "Merhaba, $userName",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary, // Antrasit
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userRole == "öğretmen"
                    ? "İşte bugünkü ders programın ve öğrencilerin."
                    : "İşte yaklaşan ders programın.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32), // Kartlardan önce nefes alma boşluğu

              // 1. TAKVİM BUTONU (Herkes görür ama herkes farklı yere gider)
              _modernMenuKart(
                context,
                "Ders Programım",
                "Yaklaşan ve geçmiş derslerinizi yönetin",
                Icons.calendar_month_outlined,
                gidecegiTakvimSayfasi,
              ),

              const SizedBox(height: 16),

              // 2. ÖĞRENCİ LİSTESİ BUTONU (Sadece Öğretmenler Görür)
              if (userRole == "öğretmen")
                _modernMenuKart(
                  context,
                  "Öğrencilerim",
                  "Öğrenci listenizi görüntüleyin ve yönetin",
                  Icons.people_outline,
                  const OgrenciListesiSayfasi(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- YENİ, PROFESYONEL MENÜ KARTI ---
  Widget _modernMenuKart(BuildContext context, String baslik, String altBaslik, IconData ikon, Widget sayfa) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200), // İnce zarif bir kenarlık
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // İkonun arkasındaki soft renkli hale
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1), // Soft mavi arka plan
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: colorScheme.secondary, size: 28), // Soft mavi ikon
              ),
              const SizedBox(width: 20),

              // Başlıklar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      altBaslik,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13
                      ),
                    ),
                  ],
                ),
              ),

              // İleri Oku
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}