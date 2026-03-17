import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'ders_provider.dart';
import 'ders_detay_sayfasi.dart';

class OzelDersTakvimi extends StatefulWidget {
  @override
  _OzelDersTakvimiState createState() => _OzelDersTakvimiState();
}

class _OzelDersTakvimiState extends State<OzelDersTakvimi> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Backend'den verileri çekiyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DersProvider>(context, listen: false).dersleriYukle();
    });
  }

  DateTime _gunuTemizle(DateTime date) => DateTime(date.year, date.month, date.day);

  void _dersEkle() {
    TextEditingController _controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Öğrenci Ekle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: "Öğrenci Adı", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  // Firebase Auth yerine şimdilik test bilgileri gönderiyoruz
                  final yeniDers = Ders(
                    ogrenciAdi: _controller.text,
                    konu: "Konu Belirlenmedi",
                    tarih: _selectedDay!,
                    saat: 0,
                    dakika: 0,
                    ogretmenId: "test_hoca_1",
                    ogretmenAdi: "Burak Hoca",
                    ogrenciId: "ogrenci_${DateTime.now().millisecondsSinceEpoch}",
                  );
                  await Provider.of<DersProvider>(context, listen: false).dersEkle(yeniDers);
                  Navigator.pop(context);
                }
              },
              child: const Text("Hızlı Ekle"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
                  leading: CircleAvatar(child: Text("${ders.saat}")),
                  title: Text(ders.ogrenciAdi),
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
      floatingActionButton: FloatingActionButton(onPressed: _dersEkle, child: const Icon(Icons.add)),
    );
  }
}