import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ders_provider.dart';
import 'ders_detay_sayfasi.dart';
import 'custom_time_picker.dart'; // YENİ EKLENEN IMPORT

class OgretmenTakvimi extends StatefulWidget {
  const OgretmenTakvimi({super.key});

  @override
  _OgretmenTakvimiState createState() => _OgretmenTakvimiState();
}

class _OgretmenTakvimiState extends State<OgretmenTakvimi> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DersProvider>(context, listen: false).dersleriYukle();
    });
  }

  DateTime _gunuTemizle(DateTime date) => DateTime(date.year, date.month, date.day);

  void _dersEkle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _DersEklePenceresi(seciliTarih: _selectedDay!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dersProvider = Provider.of<DersProvider>(context);
    final seciliGundekiDersler = dersProvider.dersler[_gunuTemizle(_selectedDay!)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim Görünümü')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => dersProvider.dersler[_gunuTemizle(day)] ?? [],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: seciliGundekiDersler.length,
              itemBuilder: (context, index) {
                final ders = seciliGundekiDersler[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Text("${ders.saat}", style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(ders.ogrenciAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(ders.konu),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => DersDetaySayfasi(ders: ders, tarih: _selectedDay!)
                  )),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _dersEkle(context),
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.add, color: Colors.white)
      ),
    );
  }
}

class _DersEklePenceresi extends StatefulWidget {
  final DateTime seciliTarih;
  const _DersEklePenceresi({required this.seciliTarih});

  @override
  State<_DersEklePenceresi> createState() => _DersEklePenceresiState();
}

class _DersEklePenceresiState extends State<_DersEklePenceresi> {
  List<dynamic> _ogrenciler = [];
  bool _isLoading = true;

  String? _seciliOgrenciId;
  String? _seciliOgrenciAdi;
  final TextEditingController _konuController = TextEditingController();

  TimeOfDay? _seciliSaat;

  @override
  void initState() {
    super.initState();
    _ogrencileriGetir();
  }

  Future<void> _ogrencileriGetir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ogretmenId = prefs.getString('user_id');
      if (ogretmenId == null) return;

      final response = await http.get(Uri.parse('http://localhost:5000/ogrencilerim?ogretmen_id=$ogretmenId'));

      if (response.statusCode == 200) {
        setState(() {
          _ogrenciler = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Öğrenciler getirilirken hata: $e");
      setState(() => _isLoading = false);
    }
  }

  void _saatSec(BuildContext context) {
    _seciliSaat ??= TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WatchStyleTimePicker( // BURADA ALT TİREYİ KALDIRDIK
          initialTime: _seciliSaat!,
          onTimeSelected: (TimeOfDay newTime) {
            setState(() {
              _seciliSaat = newTime;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Yeni Ders Ekle", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ogrenciler.isEmpty
              ? const Text("Önce 'Öğrencilerim' menüsünden öğrenci eklemelisiniz.", style: TextStyle(color: Colors.red))
              : DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Öğrenci Seçin", border: OutlineInputBorder()),
            value: _seciliOgrenciId,
            items: _ogrenciler.map<DropdownMenuItem<String>>((ogrenci) {
              return DropdownMenuItem<String>(
                value: ogrenci['uid'],
                child: Text(ogrenci['adSoyad']),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _seciliOgrenciId = val;
                _seciliOgrenciAdi = _ogrenciler.firstWhere((o) => o['uid'] == val)['adSoyad'];
              });
            },
          ),

          const SizedBox(height: 15),
          TextField(
            controller: _konuController,
            decoration: const InputDecoration(labelText: "İşlenecek Konu", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 15),

          InkWell(
            onTap: () => _saatSec(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _seciliSaat == null
                        ? "Ders Saatini Ayarlayın"
                        : "Seçilen Saat: ${_seciliSaat!.hour.toString().padLeft(2, '0')}:${_seciliSaat!.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                        fontSize: 16,
                        color: _seciliSaat == null ? Colors.grey.shade700 : Colors.black,
                        fontWeight: _seciliSaat == null ? FontWeight.normal : FontWeight.bold
                    ),
                  ),
                  const Icon(Icons.timer_outlined, color: Colors.indigo),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: () async {
              if (_seciliOgrenciId != null && _konuController.text.isNotEmpty && _seciliSaat != null) {

                final prefs = await SharedPreferences.getInstance();
                final ogretmenAd = prefs.getString('user_name') ?? "Öğretmen";
                final ogretmenId = prefs.getString('user_id') ?? "";

                final yeniDers = Ders(
                  ogrenciId: _seciliOgrenciId!,
                  ogrenciAdi: _seciliOgrenciAdi!,
                  konu: _konuController.text,
                  tarih: widget.seciliTarih,
                  saat: _seciliSaat!.hour,
                  dakika: _seciliSaat!.minute,
                  ogretmenId: ogretmenId,
                  ogretmenAdi: ogretmenAd,
                );

                await Provider.of<DersProvider>(context, listen: false).dersEkle(yeniDers);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen öğrenci, konu ve saat seçtiğinizden emin olun."))
                );
              }
            },
            child: const Text("Dersi Kaydet", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}