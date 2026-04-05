import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ders_provider.dart';
import 'custom_time_picker.dart'; // YENİ EKLENEN IMPORT

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
  late int _secilenSaat;
  late int _secilenDakika;

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

  // --- YENİ SAAT SEÇİCİ FONKSİYONU ---
  void _modernSaatSecici(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WatchStyleTimePicker(
          initialTime: TimeOfDay(hour: _secilenSaat, minute: _secilenDakika),
          onTimeSelected: (TimeOfDay newTime) {
            setState(() {
              _secilenSaat = newTime.hour;
              _secilenDakika = newTime.minute;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

            // SAAT GÖSTERİM ALANI (Modernleştirilmiş)
            InkWell(
              onTap: () => _modernSaatSecici(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(5), // Tasarım bütünlüğü için değiştirildi
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ders Saati: ${_secilenSaat.toString().padLeft(2, '0')}:${_secilenDakika.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const Icon(Icons.timer_outlined, color: Colors.indigo), // Takvimle uyumlu ikon ve renk
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
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
}