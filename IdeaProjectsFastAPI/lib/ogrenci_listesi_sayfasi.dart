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
    _ogrencileriGetir(); // Sayfa açılır açılmaz öğretmenin öğrencilerini çek
  }

  // 1. BACKEND'DEN ÖĞRENCİ LİSTESİNİ ÇEKME
  Future<void> _ogrencileriGetir() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ogretmenId = prefs.getString('user_id');

      if (ogretmenId == null) return;

      final response = await http.get(
        Uri.parse('http://10.234.204.5:8000/ogrencilerim?ogretmen_id=$ogretmenId'),
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
        Uri.parse('http://10.234.204.5:8000/ogrenci_ekle'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'ogretmenId': ogretmenId,
          'ogrenciTelefon': telefon,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        _ogrencileriGetir(); // Başarılıysa listeyi hemen yenile
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['detail']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bağlantı hatası! Sunucu çalışıyor mu?"), backgroundColor: Colors.red),
      );
    }
  }

  // 3. NUMARA GİRİŞ PENCERESİ (AÇILIR KUTU)
  void _ogrenciEkleDialogGoster() {
    final telefonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Öğrenci Ekle"),
          content: TextField(
            controller: telefonController,
            decoration: const InputDecoration(
              labelText: "Öğrencinin Telefon Numarası",
              hintText: "Örn: 05551112233",
            ),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Kutuyu kapat
                _ogrenciEkle(telefonController.text.trim()); // İsteği at
              },
              child: const Text("Ekle"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrencilerim"),
        actions: [
          // SAĞ ÜST KÖŞEDEKİ "EKLE" BUTONU
          IconButton(
            icon: const Icon(Icons.person_add, size: 28),
            onPressed: _ogrenciEkleDialogGoster,
            tooltip: "Öğrenci Ekle",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ogrenciler.isEmpty
          ? const Center(
        child: Text(
          "Henüz bir öğrenci eklemediniz.\nSağ üstteki butondan ekleyebilirsiniz.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _ogrenciler.length,
        itemBuilder: (context, index) {
          final ogrenci = _ogrenciler[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(ogrenci['adSoyad'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Tel: ${ogrenci['telefon']}"),
            ),
          );
        },
      ),
    );
  }
}