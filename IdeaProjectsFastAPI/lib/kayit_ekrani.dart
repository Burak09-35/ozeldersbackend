import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});
  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final _adController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController(); // YENİ: Telefon numarasını alacağımız kontrolcü
  final _sifreController = TextEditingController();

  String _secilenRol = 'öğretmen';

  void _kayitOl() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'adSoyad': _adController.text.trim(),
          'email': _emailController.text.trim(),
          'telefon': _telefonController.text.trim(), // YENİ: Backend'e telefonu yolluyoruz
          'password': _sifreController.text.trim(),
          'rol': _secilenRol,
        }),
      );

      if (response.statusCode == 200) {
        // DÜZELTME: Kayıt başarılıysa kullanıcıyı giriş ekranına yönlendiriyoruz ki bilgileri tam çekilsin
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kayıt başarılı! Lütfen giriş yapınız."), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Kayıt ekranını kapatıp Giriş ekranına geri döndürür
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['detail'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt sırasında hata oluştu!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _adController, decoration: const InputDecoration(labelText: "Ad Soyad")),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-posta"), keyboardType: TextInputType.emailAddress),

              // YENİ EKLENEN TELEFON KUTUSU
              TextField(
                controller: _telefonController,
                decoration: const InputDecoration(labelText: "Telefon Numarası (Örn: 05xx...)"),
                keyboardType: TextInputType.phone, // Klavyeyi numaratör olarak açar
              ),

              TextField(controller: _sifreController, decoration: const InputDecoration(labelText: "Şifre"), obscureText: true),

              const SizedBox(height: 20),
              const Text("Uygulamayı ne olarak kullanacaksınız?"),

              DropdownButton<String>(
                value: _secilenRol,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'öğretmen', child: Text("Öğretmen")),
                  DropdownMenuItem(value: 'öğrenci', child: Text("Öğrenci")),
                ],
                onChanged: (yeniDeger) {
                  setState(() {
                    _secilenRol = yeniDeger!;
                  });
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: _kayitOl,
                  child: const Text("Kayıt Ol")
              ),
            ],
          ),
        ),
      ),
    );
  }
}