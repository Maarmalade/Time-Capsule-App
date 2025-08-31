import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/media_service.dart';
import '../../models/diary_entry_model.dart';
import 'diary_editor_page.dart';
import 'diary_viewer_page.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';
import '../../widgets/nostalgia_reminder_widget.dart';

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
                      color: AppColors.primaryAccent,
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

  final MediaService _mediaService = MediaService();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  // Personal diary folder ID
  String get _personalDiaryFolderId => 'personal-diary-$userId';

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, DiaryEntryModel> _entries = {};
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
    
    try {
      // Get all media from the personal diary folder
      final mediaStream = _mediaService.streamMedia(_personalDiaryFolderId);
      final allMedia = await mediaStream.first;
      
      // Filter for diary entries in the current month
      final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      
      final diaryEntries = allMedia
          .whereType<DiaryEntryModel>()
          .where((entry) {
            final entryDate = entry.diaryDate.toDate();
            return entryDate.isAfter(start.subtract(const Duration(days: 1))) &&
                   entryDate.isBefore(end);
          })
          .toList();
      
      setState(() {
        _entries = {
          for (var e in diaryEntries)
            DateTime(e.diaryDate.toDate().year, e.diaryDate.toDate().month, e.diaryDate.toDate().day): e,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _entries = {};
        _loading = false;
      });
      debugPrint('Error fetching diary entries: $e');
    }
  }

  Color _getBorderColor(DateTime day) {
    final today = DateTime.now();
    final entry = _entries[DateTime(day.year, day.month, day.day)];
    if (day.year == today.year &&
        day.month == today.month &&
        day.day == today.day) {
      return AppColors.primaryAccent;
    } else if (entry != null) {
      // Use yellow border for favorite entries, black for regular entries
      return entry.isFavorite ? AppColors.favoriteYellow : AppColors.primaryAccent;
    } else {
      return AppColors.borderMedium;
    }
  }

  Future<bool> _showDateConfirmationDialog(DateTime selectedDate, bool isEditing) async {
    final today = DateTime.now();
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
    
    // If it's today, no confirmation needed
    if (isToday) return true;
    
    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final action = isEditing ? 'edit' : 'write';
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'Confirm Date',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to $action a diary entry for:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is not today\'s date. Are you sure you want to continue?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
            child: Text(
              'Continue',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primaryWhite,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    
    final entry = _entries[DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    )];
    
    final isEditing = entry != null;
    
    // Show confirmation dialog for non-today dates
    final confirmed = await _showDateConfirmationDialog(selectedDay, isEditing);
    if (!confirmed) return;
    
    if (entry == null) {
      // Create new diary entry using DiaryEditorPage with selected date
      final created = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryEditorPage(
            folderId: _personalDiaryFolderId,
            isSharedFolder: false,
            selectedDate: selectedDay,
          ),
        ),
      );
      if (created == true) _fetchEntries();
    } else {
      // View existing diary entry using DiaryViewerPage
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryViewerPage(
            diary: entry,
            folderId: _personalDiaryFolderId,
            canEdit: true,
            isSharedFolder: false,
          ),
        ),
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

      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAccent,
              ),
            )
          : SingleChildScrollView(
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
                          color: AppColors.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.7),
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
                              color: AppColors.primaryAccent.withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primaryAccent,
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
                                decorationColor: AppColors.primaryAccent,
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
                  
                  // Nostalgia reminders
                  NostalgiaReminderWidget(
                    mediaService: MediaService(),
                    personalDiaryFolderId: _personalDiaryFolderId,
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
                  // Add bottom padding to ensure button is accessible
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }
}
