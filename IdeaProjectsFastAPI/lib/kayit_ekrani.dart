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
  final _telefonController = TextEditingController();
  final _sifreController = TextEditingController();

  bool _isLoading = false;
  String _secilenRol = 'öğretmen';

  void _kayitOl() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.188.226.5:8080/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'adSoyad': _adController.text.trim(),
          'email': _emailController.text.trim(),
          'telefon': _telefonController.text.trim(),
          'password': _sifreController.text.trim(),
          'rol': _secilenRol,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kayıt başarılı! Lütfen giriş yapınız."), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['detail']), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt sırasında hata oluştu!"), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // İçeriği tam genişliğe yayar
            children: [
              // --- BAŞLIK ---
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 60,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Aramıza Katıl",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Hesabınızı oluşturarak planlamaya başlayın.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // --- KAYIT FORMU (KART İÇİNDE) ---
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                          controller: _adController,
                          decoration: const InputDecoration(labelText: "Ad Soyad", prefixIcon: Icon(Icons.badge_outlined))
                      ),
                      const SizedBox(height: 16),

                      TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: "E-posta", prefixIcon: Icon(Icons.email_outlined)),
                          keyboardType: TextInputType.emailAddress
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _telefonController,
                        decoration: const InputDecoration(labelText: "Telefon (Örn: 05xx...)", prefixIcon: Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      TextField(
                          controller: _sifreController,
                          decoration: const InputDecoration(labelText: "Şifre", prefixIcon: Icon(Icons.lock_outline)),
                          obscureText: true
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Hesap Türü",
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Modern Dropdown Seçimi
                      DropdownButtonFormField<String>(
                        value: _secilenRol,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.switch_account_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'öğretmen', child: Text("Öğretmen Hesabı")),
                          DropdownMenuItem(value: 'öğrenci', child: Text("Öğrenci Hesabı")),
                        ],
                        onChanged: (yeniDeger) {
                          setState(() {
                            _secilenRol = yeniDeger!;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // Kayıt Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _kayitOl,
                          child: _isLoading
                              ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                              : const Text("Kayıt Ol", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}