import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ders_provider.dart';
import 'ders_detay_sayfasi.dart';

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

      final response = await http.get(Uri.parse('http://10.234.204.5:8000/ogrencilerim?ogretmen_id=$ogretmenId'));

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
        return _WatchStyleTimePicker(
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

// ─────────────────────────────────────────────────────────────
// 24 saatlik, sonsuz kaydırmalı saat seçici
// ─────────────────────────────────────────────────────────────
class _WatchStyleTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const _WatchStyleTimePicker({
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  _WatchStyleTimePickerState createState() => _WatchStyleTimePickerState();
}

class _WatchStyleTimePickerState extends State<_WatchStyleTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;

  // Sonsuz kaydırma için büyük bir offset kullanıyoruz.
  // Gerçek liste uzunluğu: saat=24, dakika=12 (5'erli)
  static const int _loopMultiplier = 1000;
  static const int _hourCount = 24;
  static const int _minuteStepCount = 12; // 0,5,10,...,55

  final List<int> _minuteSteps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour; // 0–23

    // Dakikayı en yakın 5'liğe yuvarla
    int closestMinuteIndex = (widget.initialTime.minute / 5).round() % _minuteStepCount;
    _selectedMinute = _minuteSteps[closestMinuteIndex];

    // Ortaya yakın bir başlangıç noktası (sonsuz his verir)
    final int hourStart = (_loopMultiplier ~/ 2) * _hourCount + _selectedHour;
    final int minuteStart = (_loopMultiplier ~/ 2) * _minuteStepCount + closestMinuteIndex;

    _hourController = FixedExtentScrollController(initialItem: hourStart);
    _minuteController = FixedExtentScrollController(initialItem: minuteStart);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _saveTimeAndClose() {
    widget.onTimeSelected(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 310,
        height: 310,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Saat Seç',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SAAT ÇARKI: 00–23, sonsuz
                  SizedBox(
                    width: 65,
                    child: ListWheelScrollView.useDelegate(
                      controller: _hourController,
                      itemExtent: 46,
                      diameterRatio: 1.5,
                      useMagnifier: true,
                      magnification: 1.3,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedHour = index % _hourCount;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _hourCount * _loopMultiplier,
                        builder: (context, index) {
                          final hour = index % _hourCount;
                          final isSelected = hour == _selectedHour;
                          return Center(
                            child: Text(
                              hour.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSelected ? 28 : 20,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const Text(
                    ':',
                    style: TextStyle(color: Colors.white, fontSize: 28),
                  ),

                  // DAKİKA ÇARKI: 00–55 (5'erli), sonsuz
                  SizedBox(
                    width: 65,
                    child: ListWheelScrollView.useDelegate(
                      controller: _minuteController,
                      itemExtent: 46,
                      diameterRatio: 1.5,
                      useMagnifier: true,
                      magnification: 1.3,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMinute = _minuteSteps[index % _minuteStepCount];
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _minuteStepCount * _loopMultiplier,
                        builder: (context, index) {
                          final minute = _minuteSteps[index % _minuteStepCount];
                          final isSelected = minute == _selectedMinute;
                          return Center(
                            child: Text(
                              minute.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: isSelected ? 28 : 20,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: _saveTimeAndClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}