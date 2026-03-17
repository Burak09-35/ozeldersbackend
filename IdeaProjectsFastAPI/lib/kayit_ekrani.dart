import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // KRİTİK: Bunu eklemelisin
import 'package:http/http.dart' as http;
import 'dart:convert';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});
  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final _adController = TextEditingController(); // Yeni: İsim için
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();

  // Varsayılan rol 'öğretmen' olsun
  String _secilenRol = 'öğretmen';

  void _kayitOl() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'adSoyad': _adController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _sifreController.text.trim(),
          'rol': _secilenRol,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/anaMenu');
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['detail'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayit sirasinda hata olustu!")));
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
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-posta")),
              TextField(controller: _sifreController, decoration: const InputDecoration(labelText: "Şifre"), obscureText: true),

              const SizedBox(height: 20),
              const Text("Uygulamayı ne olarak kullanacaksınız?"),

              // ROL SEÇİMİ (Basit bir Dropdown)
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