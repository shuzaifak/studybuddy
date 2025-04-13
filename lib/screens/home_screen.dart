import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_list_item.dart';
import 'tasks_screen.dart';
import 'timer_screen.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Schedule after the current build cycle is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
      _isInit = true;
    }
  }

  Future<void> _loadData() async {
    await Provider.of<TaskProvider>(context, listen: false).loadTasks();
    await Provider.of<StudySessionProvider>(context, listen: false).loadSessions();
  }

  final List<Widget> _pages = [
    const DashboardTab(),
    const TasksScreen(),
    const TimerScreen(),
    const CalendarScreen(),
    const NotesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final sessionProvider = Provider.of<StudySessionProvider>(context);
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyBuddy', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await taskProvider.loadTasks();
          await sessionProvider.loadSessions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _calculateDailyProgress(taskProvider),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Today\'s Progress: ${(_calculateDailyProgress(taskProvider) * 100).toInt()}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Study Time Today
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Study Time Today',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _formatStudyTime(sessionProvider.getTotalStudyTimeToday()),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Upcoming Tasks
              Text(
                'Upcoming Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : taskProvider.tasks.isEmpty
                  ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No tasks yet. Tap the + button on the Tasks tab to add one!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
                  : Column(
                children: _getUpcomingTasks(taskProvider).map((task) {
                  return TaskListItem(
                    task: task,
                    onToggle: () {
                      taskProvider.toggleTaskCompletion(task.id!);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Productivity Tips
              Text(
                'Productivity Tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRandomProductivityTip(),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Next Tip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  double _calculateDailyProgress(TaskProvider taskProvider) {
    final todayTasks = taskProvider.tasks.where((task) {
      if (task.dueDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(task.dueDate!) ==
          DateFormat('yyyy-MM-dd').format(DateTime.now());
    }).toList();

    if (todayTasks.isEmpty) return 0.0;

    final completedTasks = todayTasks.where((task) => task.isCompleted).length;
    return completedTasks / todayTasks.length;
  }

  String _formatStudyTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours h $mins min';
    } else {
      return '$mins min';
    }
  }

  List<dynamic> _getUpcomingTasks(TaskProvider taskProvider) {
    final tasks = taskProvider.tasks
        .where((task) => !task.isCompleted)
        .toList();

    tasks.sort((a, b) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return tasks.take(3).toList();
  }

  String _getRandomProductivityTip() {
    final tips = [
      'Use the Pomodoro Technique: Study for 25 minutes, then take a 5-minute break.',
      'Stay hydrated while studying. Your brain needs water to function optimally.',
      'Review your notes within 24 hours of taking them to improve retention.',
      'Break large tasks into smaller, manageable chunks to avoid feeling overwhelmed.',
      'Study in a dedicated space free from distractions.',
      'Get 7-8 hours of sleep to improve memory consolidation and cognitive function.',
      'Exercise regularly to boost your energy levels and mental clarity.',
      'Try teaching the material to someone else to identify gaps in your understanding.',
      'Use active recall instead of passive reading to better retain information.',
      'Set specific, measurable goals for each study session.',
    ];

    return tips[DateTime.now().microsecond % tips.length];
  }
}