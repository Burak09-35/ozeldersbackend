import 'package:flutter/material.dart';

class WatchStyleTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const WatchStyleTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<WatchStyleTimePicker> createState() => _WatchStyleTimePickerState();
}

class _WatchStyleTimePickerState extends State<WatchStyleTimePicker> {
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