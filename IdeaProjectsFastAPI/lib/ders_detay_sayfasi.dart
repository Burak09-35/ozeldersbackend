import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ders_provider.dart';

class DersDetaySayfasi extends StatefulWidget {
  final Ders ders;
  final DateTime tarih;

  const DersDetaySayfasi({super.key, required this.ders, required this.tarih});

  @override
  State<DersDetaySayfasi> createState() => _DersDetaySayfasiState();
}

class _DersDetaySayfasiState extends State<DersDetaySayfasi> {
  late TextEditingController _adController;
  late TextEditingController _konuController;
  late bool _odemeAlindi;
  late bool _katilimTamamlandi;
  int? _secilenSaat;
  int? _secilenDakika;

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController(text: widget.ders.ogrenciAdi);
    _konuController = TextEditingController(text: widget.ders.konu);
    _odemeAlindi = widget.ders.odemeAlindi;
    _katilimTamamlandi = widget.ders.katilimTamamlandi;
    _secilenSaat = widget.ders.saat;
    _secilenDakika = widget.ders.dakika;
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı burada tanımlıyoruz
    final dersProv = Provider.of<DersProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Ders Detayı")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _adController,
              decoration: const InputDecoration(labelText: "Öğrenci Adı"),
            ),
            TextField(
              controller: _konuController,
              decoration: const InputDecoration(labelText: "Konu"),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text("Ders Saati: ${_secilenSaat}:${_secilenDakika.toString().padLeft(2, '0')}"),
              trailing: const Icon(Icons.access_time),
              onTap: () => _saatSecici(context),
            ),
            SwitchListTile(
              title: const Text("Katılım Tamamlandı"),
              subtitle: const Text("Öğrenci derse geldi mi?"),
              value: _katilimTamamlandi,
              onChanged: (v) => setState(() => _katilimTamamlandi = v),
            ),
            SwitchListTile(
              title: const Text("Ödeme Alındı"),
              subtitle: const Text("Ders ücreti ödendi mi?"),
              value: _odemeAlindi,
              onChanged: (v) => setState(() => _odemeAlindi = v),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // DÜZELTME: dersGuncelle artık sadece 2 parametre alıyor: ID ve DATA
                await dersProv.dersGuncelle(
                    widget.ders.id!,
                    {
                      'ogrenciAdi': _adController.text,
                      'konu': _konuController.text,
                      'odemeAlindi': _odemeAlindi,
                      'katilimTamamlandi': _katilimTamamlandi,
                      'saat': _secilenSaat,
                      'dakika': _secilenDakika,
                    }
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Değişiklikleri Kaydet"),
            )
          ],
        ),
      ),
    );
  }

  // Saat seçiciyi biraz daha gerçekçi yapalım
  Future<void> _saatSecici(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _secilenSaat!, minute: _secilenDakika!),
    );
    if (picked != null) {
      setState(() {
        _secilenSaat = picked.hour;
        _secilenDakika = picked.minute;
      });
    }
  }
}