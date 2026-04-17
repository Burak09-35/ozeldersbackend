import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OgrenciListesiSayfasi extends StatefulWidget {
  const OgrenciListesiSayfasi({super.key});

  @override
  State<OgrenciListesiSayfasi> createState() => _OgrenciListesiSayfasiState();
}

class _OgrenciListesiSayfasiState extends State<OgrenciListesiSayfasi> {
  List<dynamic> _ogrenciler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ogrencileriGetir();
  }

  // 1. BACKEND'DEN ÖĞRENCİ LİSTESİNİ ÇEKME
  Future<void> _ogrencileriGetir() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ogretmenId = prefs.getString('user_id');

      if (ogretmenId == null) return;

      final response = await http.get(
        Uri.parse('http://10.188.226.5:8080/ogrencilerim?ogretmen_id=$ogretmenId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _ogrenciler = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Öğrenciler getirilirken hata: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. YENİ ÖĞRENCİ EKLEME FONKSİYONU
  Future<void> _ogrenciEkle(String telefon) async {
    if (telefon.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ogretmenId = prefs.getString('user_id');

      if (ogretmenId == null) return;

      final response = await http.post(
        Uri.parse('http://10.188.226.5:8080/ogrenci_ekle'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'ogretmenId': ogretmenId,
          'ogrenciTelefon': telefon,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green.shade600),
        );
        _ogrencileriGetir();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['detail']), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bağlantı hatası! Sunucu çalışıyor mu?"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // 3. NUMARA GİRİŞ PENCERESİ (Modernleştirilmiş Dialog)
  void _ogrenciEkleDialogGoster() {
    final telefonController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            "Yeni Öğrenci Ekle",
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: telefonController,
            decoration: const InputDecoration(
              labelText: "Telefon Numarası",
              hintText: "Örn: 0555...",
              prefixIcon: Icon(Icons.phone_outlined), // İkon eklendi
            ),
            keyboardType: TextInputType.phone,
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _ogrenciEkle(telefonController.text.trim());
              },
              // Buton stili main.dart'tan otomatik çekilecek
              child: const Text("Ekle"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrencilerim"),
        actions: [
          // SAĞ ÜST KÖŞEDEKİ "EKLE" BUTONU (Daha modern ikon)
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 26),
            onPressed: _ogrenciEkleDialogGoster,
            tooltip: "Öğrenci Ekle",
          ),
          const SizedBox(width: 8), // Sağdan hafif boşluk
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ogrenciler.isEmpty
        // --- BOŞ LİSTE TASARIMI ---
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "Henüz öğrenci eklemediniz.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sağ üstteki butona tıklayarak numarası ile öğrenci davet edebilirsiniz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        )
        // --- ÖĞRENCİ LİSTESİ TASARIMI ---
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _ogrenciler.length,
          itemBuilder: (context, index) {
            final ogrenci = _ogrenciler[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200), // Şık ince kenarlık
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1), // Soft mavi arka plan
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline_rounded, color: colorScheme.secondary),
                ),
                title: Text(
                  ogrenci['adSoyad'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text("Tel: ${ogrenci['telefon']}", style: TextStyle(color: Colors.grey.shade600)),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
              ),
            );
          },
        ),
      ),
    );
  }
}