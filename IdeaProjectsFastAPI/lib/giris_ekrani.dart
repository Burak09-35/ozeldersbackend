import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GiriisEkrani extends StatefulWidget {
  const GiriisEkrani({super.key});
  @override
  State<GiriisEkrani> createState() => _GiriisEkraniState();
}

class _GiriisEkraniState extends State<GiriisEkrani> {
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();

  void _girisYap() async {
    final email = _emailController.text.trim();
    final sifre = _sifreController.text.trim();

    // 1. BURADA ASLA FirebaseAuth KODU OLMAMALI!
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': sifre,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Kullanıcı bilgilerini telefona kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['user']['uid']);
        await prefs.setString('user_role', data['user']['rol']);
        await prefs.setString('user_name', data['user']['adSoyad']);

        print("KAYDEDİLEN ID: ${data['user']['uid']}");
        print("KAYDEDİLEN ISIM: ${data['user']['adSoyad']}");

        Navigator.pushReplacementNamed(context, '/anaMenu');
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${errorData['detail']}")),
        );
      }
    } catch (e) {
      print("DETAYLI HATA: $e"); // Konsola bunu yazdır ki görelim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bağlantı hatası!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade400], begin: Alignment.topCenter)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 30)),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(controller: _emailController, decoration: const InputDecoration(filled: true, fillColor: Colors.white, hintText: "E-posta")),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(controller: _sifreController, obscureText: true, decoration: const InputDecoration(filled: true, fillColor: Colors.white, hintText: "Şifre")),
              ),
              ElevatedButton(onPressed: _girisYap, child: const Text("Giriş")),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/kayit'), child: const Text("Kayıt Ol", style: TextStyle(color: Colors.white)))
            ],
          ),
        ),
      ),
    );
  }
}