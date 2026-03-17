import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ders_provider.dart';
import 'ders_detay_sayfasi.dart';

class OgrenciListesiSayfasi extends StatefulWidget {
  const OgrenciListesiSayfasi({super.key});

  @override
  State<OgrenciListesiSayfasi> createState() => _OgrenciListesiSayfasiState();
}

class _OgrenciListesiSayfasiState extends State<OgrenciListesiSayfasi> {
  String _aramaMetni = "";

  @override
  Widget build(BuildContext context) {
    final dersProv = Provider.of<DersProvider>(context);
    // İsimle arama fonksiyonu zaten Provider'da vardı, onu kullanıyoruz
    final filtrelenmisDersler = dersProv.ogrenciDersleriniGetirByIsim(_aramaMetni);

    return Scaffold(
    appBar: AppBar(title: const Text("Öğrenci Listesi")),
    body: Column(
    children: [
    Padding(
    padding: const EdgeInsets.all(10.0),
    child: TextField(
    decoration: const InputDecoration(
    hintText: "Öğrenci Ara...",
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
    ),
    onChanged: (value) => setState(() => _aramaMetni = value),
    ),
    ),
    Expanded(
    child: ListView.builder(
    itemCount: filtrelenmisDersler.length,
    itemBuilder: (context, index) {
    final ders = filtrelenmisDersler[index];
    return ListTile(
    title: Text(ders.ogrenciAdi),
    subtitle: Text("${ders.konu} - ${ders.tarih.day}/${ders.tarih.month}"),
    trailing: Icon(
    ders.odemeAlindi ? Icons.check_circle : Icons.error_outline,
    color: ders.odemeAlindi ? Colors.green : Colors.red,
    ),
    onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => DersDetaySayfasi(ders: ders, tarih: ders.tarih),
    ),
    ),
    );
    },
    ),
    ),
    ],
    ),
    );
  }
}