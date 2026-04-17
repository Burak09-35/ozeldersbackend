import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ders_provider.dart';
import 'custom_time_picker.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Ders Detayı")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // main.dart'taki temiz textfield tasarımı devreye girer
            TextField(
              controller: _adController,
              decoration: const InputDecoration(
                labelText: "Öğrenci Adı",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _konuController,
              decoration: const InputDecoration(
                labelText: "Konu",
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // SAAT GÖSTERİM ALANI (Premium Tasarım)
            InkWell(
              onTap: () => _modernSaatSecici(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ders Saati: ${_secilenSaat.toString().padLeft(2, '0')}:${_secilenDakika.toString().padLeft(2, '0')}",
                      style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Icon(Icons.access_time_filled, color: colorScheme.secondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // KART İÇİNDE DURUM YÖNETİMİ
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text("Katılım Tamamlandı", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    subtitle: Text("Öğrenci derse geldi mi?", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    activeColor: Colors.green,
                    value: _katilimTamamlandi,
                    onChanged: (v) => setState(() => _katilimTamamlandi = v),
                    secondary: Icon(Icons.check_circle_outline, color: _katilimTamamlandi ? Colors.green : Colors.grey),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text("Ödeme Alındı", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    subtitle: Text("Ders ücreti ödendi mi?", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    activeColor: colorScheme.secondary,
                    value: _odemeAlindi,
                    onChanged: (v) => setState(() => _odemeAlindi = v),
                    secondary: Icon(Icons.payments_outlined, color: _odemeAlindi ? colorScheme.secondary : Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Buton stili artık main.dart'tan geliyor
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
              ),
            )
          ],
        ),
      ),
    );
  }
}