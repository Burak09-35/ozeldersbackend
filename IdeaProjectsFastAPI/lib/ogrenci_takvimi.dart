// ogrenci_takvimi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'ders_provider.dart';

class OgrenciTakvimi extends StatefulWidget {
  const OgrenciTakvimi({super.key});

  @override
  State<OgrenciTakvimi> createState() => _OgrenciTakvimiState();
}

class _OgrenciTakvimiState extends State<OgrenciTakvimi> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Sayfa açıldığında dersleri yükle
    Future.delayed(Duration.zero, () {
      Provider.of<DersProvider>(context, listen: false).dersleriYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dersProvider = Provider.of<DersProvider>(context);
    // Seçili günün derslerini provider'dan güvenli bir şekilde alıyoruz
    final gunKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final seciliGunDersleri = dersProvider.dersler[gunKey] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Ders Programım")),
      body: Column(
        children: [
          // Takvim Bileşeni (Öğrenci için Salt Okunur gibi çalışır)
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
            onFormatChanged: (format) {
              setState(() { _calendarFormat = format; });
            },
            eventLoader: (day) {
              final dKey = DateTime(day.year, day.month, day.day);
              return dersProvider.dersler[dKey] ?? [];
            },
          ),
          const Divider(),
          // Seçilen günün derslerinin listesi
          Expanded(
            child: ListView.builder(
              itemCount: seciliGunDersleri.length,
              itemBuilder: (context, index) {
                final ders = seciliGunDersleri[index];
                return ListTile(
                  leading: const Icon(Icons.book, color: Colors.indigo),
                  title: Text(ders.konu),
                  subtitle: Text("Saat: ${ders.saat}:${ders.dakika.toString().padLeft(2, '0')} - Hoca: ${ders.ogretmenAdi}"),
                  trailing: Icon(
                    ders.odemeAlindi ? Icons.check_circle : Icons.pending,
                    color: ders.odemeAlindi ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // DİKKAT: FloatingActionButton (Ders Ekleme Butonu) BURADA YOK!
    );
  }
}