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
  bool _isLoading = false; // Kullanıcı butona basınca yükleniyor efekti vermek için

  void _girisYap() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final sifre = _sifreController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': sifre,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['user']['uid']);
        await prefs.setString('user_role', data['user']['rol']);
        await prefs.setString('user_name', data['user']['adSoyad']);
        await prefs.setString('user_telefon', data['user']['telefon']);

        print("KAYDEDİLEN ID: ${data['user']['uid']}");
        print("KAYDEDİLEN ROL: ${data['user']['rol']}");

        Navigator.pushReplacementNamed(context, '/anaMenu');
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${errorData['detail']}"),
            backgroundColor: Colors.redAccent, // Hata mesajı için dikkat çekici renk
          ),
        );
      }
    } catch (e) {
      print("DETAYLI HATA: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bağlantı hatası! Sunucu çalışıyor mu?"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerine kolay erişim için
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Arka planı artık main.dart'tan alıyor (Açık gri/kırık beyaz)
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO VE BAŞLIK KISMI ---
                Icon(
                  Icons.menu_book_rounded, // Uygulamanın eğitim konseptine uygun bir ikon
                  size: 80,
                  color: colorScheme.primary, // Derin Antrasit
                ),
                const SizedBox(height: 24),
                Text(
                  "Hoş Geldiniz",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Özel Ders Asistanı'na giriş yapın",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                // --- GİRİŞ FORMU (KART İÇİNDE) ---
                Card(
                  elevation: 2, // main.dart'taki hafif gölgeyi kullanır
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "E-posta",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _sifreController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Şifre",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Giriş Butonu (Genişletilmiş)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _girisYap,
                            child: _isLoading
                                ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                                : const Text("Giriş Yap", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- KAYIT OL LİNKİ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Hesabınız yok mu?", style: TextStyle(color: Colors.grey.shade700)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/kayit'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.secondary, // Soft Mavi
                      ),
                      child: const Text("Kayıt Ol", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}