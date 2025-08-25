import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/diary_entry_model.dart';
import '../../services/diary_service.dart';
import 'diary_entry_page.dart';
import 'diary_viewer_page.dart';
import '../../constants/route_constants.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';

class DigitalDiaryPage extends StatefulWidget {
  const DigitalDiaryPage({super.key});

  @override
  State<DigitalDiaryPage> createState() => _DigitalDiaryPageState();
}

class _DigitalDiaryPageState extends State<DigitalDiaryPage> {
  Future<DateTime?> showMonthYearPicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Select month and year',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                height: 120,
                child: Column(
                  children: [
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(30, (i) => 2000 + i)
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text(
                                '$y',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (y) {
                        if (y != null) setState(() => selectedYear = y);
                      },
                    ),
                    DropdownButton<int>(
                      value: selectedMonth,
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                _monthName(m),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
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
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(selectedYear, selectedMonth),
                  ),
                  child: Text(
                    'OK',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.accentBlue,
                    ),
                  ),
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
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
      userId,
      _focusedDay.year,
      _focusedDay.month,
    );
    setState(() {
      _entries = {
        for (var e in entries)
          DateTime(e.date.year, e.date.month, e.date.day): e,
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
      return AppColors.accentBlue;
    } else if (entry?.isFavorite == true) {
      return AppColors.warningAmber;
    } else if (entry != null) {
      return AppColors.successGreen;
    } else {
      return AppColors.borderMedium;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final entry =
        _entries[DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        )];
    if (entry == null) {
      final created = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryEntryPage(date: selectedDay)),
      );
      if (created == true) _fetchEntries();
    } else {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryViewerPage(entry: entry)),
      );
      if (updated == true) _fetchEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        leading: BackButton(
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Digital Diary',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.person,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pushNamed(context, Routes.profile),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accentBlue,
              ),
            )
          : Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: AppSpacing.cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                        _fetchEntries();
                      },
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        defaultTextStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        selectedTextStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryWhite,
                          fontWeight: AppTypography.medium,
                        ),
                        todayTextStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryWhite,
                          fontWeight: AppTypography.medium,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: AppTypography.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: AppColors.textPrimary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        weekendStyle: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _getBorderColor(day),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _getBorderColor(day),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: AppTypography.medium,
                                ),
                              ),
                            ),
                          );
                        },
                        headerTitleBuilder: (context, day) {
                          return GestureDetector(
                            onTap: () async {
                              final picked = await showMonthYearPicker(
                                context,
                                day,
                              );
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
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.textPrimary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.accentBlue,
                              ),
                            ),
                          );
                        },
                      ),
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      headerVisible: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.minTouchTarget,
                    child: ElevatedButton(
                      onPressed: () => _onDaySelected(DateTime.now(), _focusedDay),
                      child: Text(
                        'Write Diary for today!',
                        style: AppTypography.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
