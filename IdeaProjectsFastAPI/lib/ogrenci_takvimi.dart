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
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    Future.delayed(Duration.zero, () {
      Provider.of<DersProvider>(context, listen: false).dersleriYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dersProvider = Provider.of<DersProvider>(context);
    final gunKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final seciliGunDersleri = dersProvider.dersler[gunKey] ?? [];

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Ders Programım")),
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
                  startingDayOfWeek: StartingDayOfWeek.monday, // Haftayı Pazartesi başlat
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    final dKey = DateTime(day.year, day.month, day.day);
                    return dersProvider.dersler[dKey] ?? [];
                  },

                  // Üst Bilgi Tasarımı
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false, // Kalabalığı önlemek için gizledik
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),

                  // Gün İsimleri Tasarımı
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold), // Hafta sonu mavi
                  ),

                  // Takvim İçi Günlerin Tasarımı
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false, // Temiz bir görünüm için önceki/sonraki ay günlerini gizle
                    todayDecoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.2), // Bugünün rengi açık mavi
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary, // Seçili gün koyu antrasit
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    markerDecoration: BoxDecoration(
                      color: colorScheme.secondary, // Ders olan günlerin altındaki nokta
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // --- DERSLER LİSTESİ ---
            Expanded(
              child: seciliGunDersleri.isEmpty
                  ? Center(
                child: Text(
                    "Bu tarihte planlı dersiniz yok.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: seciliGunDersleri.length,
                itemBuilder: (context, index) {
                  final ders = seciliGunDersleri[index];
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
                          color: colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.menu_book_rounded, color: colorScheme.secondary),
                      ),
                      title: Text(
                        ders.konu,
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("Saat: ${ders.saat.toString().padLeft(2, '0')}:${ders.dakika.toString().padLeft(2, '0')} • Hoca: ${ders.ogretmenAdi}"),
                      ),
                      trailing: Icon(
                        ders.odemeAlindi ? Icons.check_circle : Icons.pending,
                        color: ders.odemeAlindi ? Colors.green.shade400 : Colors.orange.shade400,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}