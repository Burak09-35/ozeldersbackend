import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ders_provider.dart';
import 'ders_detay_sayfasi.dart';
import 'custom_time_picker.dart';

class OgretmenTakvimi extends StatefulWidget {
  const OgretmenTakvimi({super.key});

  @override
  _OgretmenTakvimiState createState() => _OgretmenTakvimiState();
}

class _OgretmenTakvimiState extends State<OgretmenTakvimi> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _DersEklePenceresi(seciliTarih: _selectedDay!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dersProvider = Provider.of<DersProvider>(context);
    final seciliGundekiDersler = dersProvider.dersler[_gunuTemizle(_selectedDay!)] ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim Görünümü')),
      body: SafeArea(
        child: Column(
          children: [
            // --- PREMIUM TAKVİM TASARIMI ---
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) => dersProvider.dersler[_gunuTemizle(day)] ?? [],

                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),

                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
                  ),

                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    markerDecoration: BoxDecoration(
                      color: colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // --- DERSLER LİSTESİ ---
            Expanded(
              child: seciliGundekiDersler.isEmpty
                  ? Center(
                child: Text(
                    "Bu tarihte planlı dersiniz yok.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: seciliGundekiDersler.length,
                itemBuilder: (context, index) {
                  final ders = seciliGundekiDersler[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.secondary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                        ),
                        child: Text(
                            "${ders.saat.toString().padLeft(2, '0')}:${ders.dakika.toString().padLeft(2, '0')}",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      ),
                      title: Text(
                        ders.ogrenciAdi,
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(ders.konu),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => DersDetaySayfasi(ders: ders, tarih: _selectedDay!)
                      )),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _dersEkle(context),
          child: const Icon(Icons.add)
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

      final response = await http.get(Uri.parse('http://10.188.226.5:8080/ogrencilerim?ogretmen_id=$ogretmenId'));

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
        return WatchStyleTimePicker(
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 32
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              "Yeni Ders Ekle",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary)
          ),
          const SizedBox(height: 24),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ogrenciler.isEmpty
              ? const Text("Önce 'Öğrencilerim' menüsünden öğrenci eklemelisiniz.", style: TextStyle(color: Colors.red))
              : DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Öğrenci Seçin"),
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

          const SizedBox(height: 16),
          TextField(
            controller: _konuController,
            decoration: const InputDecoration(labelText: "İşlenecek Konu"),
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap: () => _saatSec(context),
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
                    _seciliSaat == null
                        ? "Ders Saatini Ayarlayın"
                        : "Seçilen Saat: ${_seciliSaat!.hour.toString().padLeft(2, '0')}:${_seciliSaat!.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                        fontSize: 16,
                        color: _seciliSaat == null ? Colors.grey.shade600 : colorScheme.primary,
                        fontWeight: _seciliSaat == null ? FontWeight.normal : FontWeight.bold
                    ),
                  ),
                  Icon(Icons.access_time_filled, color: colorScheme.secondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
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
            child: const Text("Dersi Kaydet"),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}