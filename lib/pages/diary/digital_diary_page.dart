import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/diary_entry_model.dart';
import '../../services/diary_service.dart';
import 'diary_entry_page.dart';
import 'diary_viewer_page.dart';
import '../../routes.dart';




class DigitalDiaryPage extends StatefulWidget {
  const DigitalDiaryPage({super.key});

  @override
  State<DigitalDiaryPage> createState() => _DigitalDiaryPageState();
}

class _DigitalDiaryPageState extends State<DigitalDiaryPage> {
  Future<DateTime?> showMonthYearPicker(BuildContext context, DateTime initialDate) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select month and year'),
              content: SizedBox(
                height: 120,
                child: Column(
                  children: [
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(30, (i) => 2000 + i)
                          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      onChanged: (y) {
                        if (y != null) setState(() => selectedYear = y);
                      },
                    ),
                    DropdownButton<int>(
                      value: selectedMonth,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m))))
                          .toList(),
                      onChanged: (m) {
                        if (m != null) setState(() => selectedMonth = m);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, DateTime(selectedYear, selectedMonth)),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
  final DiaryService _diaryService = DiaryService();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, DiaryEntry> _entries = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() => _loading = true);
    final entries = await _diaryService.fetchDiaryEntriesForMonth(
        userId, _focusedDay.year, _focusedDay.month);
    setState(() {
      _entries = {
        for (var e in entries)
          DateTime(e.date.year, e.date.month, e.date.day): e
      };
      _loading = false;
    });
  }

  Color _getBorderColor(DateTime day) {
    final today = DateTime.now();
    final entry = _entries[DateTime(day.year, day.month, day.day)];
    if (day.year == today.year &&
        day.month == today.month &&
        day.day == today.day) {
      return Colors.red;
    } else if (entry?.isFavorite == true) {
      return Colors.yellow;
    } else if (entry != null) {
      return Colors.grey;
    } else {
      return Colors.black;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final entry = _entries[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)];
    if (entry == null) {
      final created = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryEntryPage(date: selectedDay),
        ),
      );
      if (created == true) _fetchEntries();
    } else {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryViewerPage(entry: entry),
        ),
      );
      if (updated == true) _fetchEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Digital Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, Routes.profile),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    _fetchEntries();
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _getBorderColor(day),
                            width: 2,
                          ),
                        ),
                        child: Center(child: Text('${day.day}')),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _getBorderColor(day),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                    headerTitleBuilder: (context, day) {
                      return GestureDetector(
                        onTap: () async {
                          final picked = await showMonthYearPicker(context, day);
                          if (picked != null) {
                            setState(() {
                              _focusedDay = picked;
                              _selectedDay = picked;
                            });
                            _fetchEntries();
                          }
                        },
                        child: Text(
                          '${_monthName(day.month)} ${day.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      );
                    },
                  ),
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  headerVisible: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _onDaySelected(DateTime.now(), _focusedDay),
                  child: const Text('Write Diary for today!'),
                ),
              ],
            ),
    );
  }
}