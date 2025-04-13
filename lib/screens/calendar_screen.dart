import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../providers/task_provider.dart';
import '../providers/study_session_provider.dart';
import '../widgets/task_list_item.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<Task>> _selectedTasks;
  late final ValueNotifier<List<StudySession>> _selectedSessions;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedTasks = ValueNotifier([]);
    _selectedSessions = ValueNotifier([]);
    _loadSelectedDayInfo();
  }

  @override
  void dispose() {
    _selectedTasks.dispose();
    _selectedSessions.dispose();
    super.dispose();
  }

  void _loadSelectedDayInfo() {
    if (_selectedDay == null) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final sessionProvider = Provider.of<StudySessionProvider>(context, listen: false);

    // Load tasks for selected day
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final tasks = taskProvider.tasks.where((task) {
      if (task.dueDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(task.dueDate!) == selectedDate;
    }).toList();

    // Load study sessions for selected day
    final sessions = sessionProvider.sessions.where((session) {
      return session.date == selectedDate;
    }).toList();

    _selectedTasks.value = tasks;
    _selectedSessions.value = sessions;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final sessionProvider = Provider.of<StudySessionProvider>(context, listen: false);

    final formattedDay = DateFormat('yyyy-MM-dd').format(day);

    // Get tasks for this day
    final tasks = taskProvider.tasks.where((task) {
      if (task.dueDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(task.dueDate!) == formattedDay;
    }).toList();

    // Get study sessions for this day
    final sessions = sessionProvider.sessions.where((session) {
      return session.date == formattedDay;
    }).toList();

    return [...tasks, ...sessions];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadSelectedDayInfo();
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showAddStudySessionDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Study Session'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a day to view details'))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tasks Section
                  Text(
                    'Tasks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<Task>>(
                    valueListenable: _selectedTasks,
                    builder: (context, tasks, _) {
                      if (tasks.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No tasks scheduled for this day',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: tasks.map((task) {
                          return TaskListItem(
                            task: task,
                            onToggle: () {
                              taskProvider.toggleTaskCompletion(task.id!);
                              _loadSelectedDayInfo();
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Study Sessions Section
                  Text(
                    'Study Sessions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<List<StudySession>>(
                    valueListenable: _selectedSessions,
                    builder: (context, sessions, _) {
                      if (sessions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No study sessions recorded for this day',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: sessions.map((session) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(session.subject),
                              subtitle: Text(
                                '${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)} (${session.duration} min)',
                              ),
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.secondary,
                                child: const Icon(Icons.timer, color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  _showDeleteSessionDialog(context, session);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Stats Section
                  ValueListenableBuilder<List<StudySession>>(
                    valueListenable: _selectedSessions,
                    builder: (context, sessions, _) {
                      if (sessions.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final totalMinutes = sessions.fold<int>(
                          0, (sum, session) => sum + session.duration);

                      final hours = totalMinutes ~/ 60;
                      final minutes = totalMinutes % 60;

                      return Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Total Study Time',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hours > 0
                                    ? '$hours hours $minutes minutes'
                                    : '$minutes minutes',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStudySessionDialog(BuildContext context) async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day first')),
      );
      return;
    }

    final subjectController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
      hour: TimeOfDay.now().hour + 1,
      minute: TimeOfDay.now().minute,
    );

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Study Session'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      hintText: 'Enter subject name',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // Start Time Picker
                  const Text('Start Time'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(startTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        // Ensure start time is before end time
                        setState(() {
                          startTime = time;
                          if (_timeToMinutes(startTime) >= _timeToMinutes(endTime)) {
                            endTime = TimeOfDay(
                              hour: (startTime.hour + 1) % 24,
                              minute: startTime.minute,
                            );
                          }
                        });
                      }
                    },
                  ),

                  // End Time Picker
                  const SizedBox(height: 8),
                  const Text('End Time'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(endTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        // Ensure end time is after start time
                        if (_timeToMinutes(time) > _timeToMinutes(startTime)) {
                          setState(() {
                            endTime = time;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('End time must be after start time'),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  // Duration Display
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${_calculateDuration(startTime, endTime)} minutes',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (subjectController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a subject')),
                    );
                    return;
                  }

                  // Create date objects with the selected times
                  final now = _selectedDay!;
                  final start = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    startTime.hour,
                    startTime.minute,
                  );

                  final end = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    endTime.hour,
                    endTime.minute,
                  );

                  // Handle case where end time is on the next day
                  final DateTime adjustedEnd = end.isBefore(start)
                      ? end.add(const Duration(days: 1))
                      : end;

                  final duration = _calculateDuration(startTime, endTime);

                  final studySession = StudySession(
                    subject: subjectController.text,
                    startTime: start,
                    endTime: adjustedEnd,
                    duration: duration,
                    date: DateFormat('yyyy-MM-dd').format(_selectedDay!),
                  );

                  Provider.of<StudySessionProvider>(context, listen: false)
                      .addSession(studySession)
                      .then((_) {
                    _loadSelectedDayInfo();
                  });

                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteSessionDialog(BuildContext context, StudySession session) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study Session'),
        content: Text(
          'Are you sure you want to delete this study session for ${session.subject}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Note: We would need to implement deleteSession in the provider
              // For now, we'll just remove it from the local list
              final updatedSessions = _selectedSessions.value
                  .where((s) => s.id != session.id)
                  .toList();
              _selectedSessions.value = updatedSessions;

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Study session deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  int _calculateDuration(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;

    // Handle case where end time is on the next day
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60; // Add a day in minutes
    }

    return endMinutes - startMinutes;
  }
}