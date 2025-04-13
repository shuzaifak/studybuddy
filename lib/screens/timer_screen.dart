import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/study_session.dart';
import '../providers/study_session_provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  final TextEditingController _subjectController = TextEditingController();
  Timer? _timer;
  int _timeInSeconds = 25 * 60; // default 25 minutes
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isBreak = false;
  DateTime? _startTime;
  late AnimationController _animationController;

  // Pomodoro settings
  int _focusDuration = 25; // in minutes
  int _shortBreakDuration = 5; // in minutes
  int _longBreakDuration = 15; // in minutes
  int _sessionsBeforeLongBreak = 4;
  int _completedSessions = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeInSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subject before starting the timer'),
        ),
      );
      return;
    }

    setState(() {
      if (!_isPaused) {
        _timeInSeconds = _isBreak
            ? (_completedSessions % _sessionsBeforeLongBreak == 0 && _completedSessions > 0
            ? _longBreakDuration * 60
            : _shortBreakDuration * 60)
            : _focusDuration * 60;
        _elapsedSeconds = 0;
      }

      _isRunning = true;
      _isPaused = false;
      _startTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
    });

    _animationController.duration = Duration(seconds: _timeInSeconds);
    _animationController.reverse(from: 1.0 - (_elapsedSeconds / _timeInSeconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;

        if (_elapsedSeconds >= _timeInSeconds) {
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animationController.stop();

    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _animationController.reset();

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _elapsedSeconds = 0;
    });
  }

  void _completeSession() {
    _timer?.cancel();
    _animationController.reset();

    // Only save study sessions, not breaks
    if (!_isBreak) {
      final studySessionProvider = Provider.of<StudySessionProvider>(context, listen: false);
      final now = DateTime.now();

      final session = StudySession(
        subject: _subjectController.text,
        startTime: _startTime!,
        endTime: now,
        duration: _focusDuration,
        date: DateFormat('yyyy-MM-dd').format(now),
      );

      studySessionProvider.addSession(session);

      setState(() {
        _completedSessions++;
      });
    }

    // Show completion dialog
    _showCompletionDialog();

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isBreak = !_isBreak;
      _elapsedSeconds = 0;
    });
  }

  void _showCompletionDialog() {
    final nextSessionText = _isBreak
        ? 'Time for a study session!'
        : _completedSessions % _sessionsBeforeLongBreak == 0
        ? 'Time for a long break!'
        : 'Time for a short break!';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBreak ? 'Break Completed!' : 'Session Completed!'),
        content: Text('$nextSessionText Would you like to continue?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimer();
            },
            child: const Text('Stop'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startTimer();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    int focusDuration = _focusDuration;
    int shortBreakDuration = _shortBreakDuration;
    int longBreakDuration = _longBreakDuration;
    int sessionsBeforeLongBreak = _sessionsBeforeLongBreak;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Timer Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Focus Duration (minutes)'),
                  Slider(
                    value: focusDuration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$focusDuration min',
                    onChanged: (value) {
                      setState(() {
                        focusDuration = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Short Break Duration (minutes)'),
                  Slider(
                    value: shortBreakDuration.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    label: '$shortBreakDuration min',
                    onChanged: (value) {
                      setState(() {
                        shortBreakDuration = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Long Break Duration (minutes)'),
                  Slider(
                    value: longBreakDuration.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    label: '$longBreakDuration min',
                    onChanged: (value) {
                      setState(() {
                        longBreakDuration = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Sessions Before Long Break'),
                  Slider(
                    value: sessionsBeforeLongBreak.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '$sessionsBeforeLongBreak sessions',
                    onChanged: (value) {
                      setState(() {
                        sessionsBeforeLongBreak = value.toInt();
                      });
                    },
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
                  // Save settings
                  this.setState(() {
                    _focusDuration = focusDuration;
                    _shortBreakDuration = shortBreakDuration;
                    _longBreakDuration = longBreakDuration;
                    _sessionsBeforeLongBreak = sessionsBeforeLongBreak;

                    // Reset timer with new settings if not running
                    if (!_isRunning) {
                      _timeInSeconds = _isBreak
                          ? (_completedSessions % _sessionsBeforeLongBreak == 0 && _completedSessions > 0
                          ? _longBreakDuration * 60
                          : _shortBreakDuration * 60)
                          : _focusDuration * 60;
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingSeconds = _timeInSeconds - _elapsedSeconds;
    final progress = 1 - (_elapsedSeconds / _timeInSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _isRunning ? null : _showSettingsDialog,
          ),
        ],
      ),
    body: Center(
    child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(  // Add this
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
              // Session type and count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isBreak ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isBreak
                      ? (_completedSessions % _sessionsBeforeLongBreak == 0 && _completedSessions > 0
                      ? 'Long Break'
                      : 'Short Break')
                      : 'Focus Session ${_completedSessions + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isBreak ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Timer display
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          color: _isBreak ? Colors.green : theme.colorScheme.primary,
                        );
                      },
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _formatTime(remainingSeconds),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _isBreak ? 'Break Time' : 'Stay Focused',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Subject input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'What are you studying?',
                    hintText: 'Enter subject',
                    prefixIcon: const Icon(Icons.subject),
                    enabled: !_isRunning && !_isPaused,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Timer controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning && !_isPaused)
                    ElevatedButton.icon(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (_isRunning)
                    ElevatedButton.icon(
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (_isPaused) ...[
                    ElevatedButton.icon(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (_isRunning || _isPaused) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Skip button (only when timer is running)
              if (_isRunning)
                TextButton.icon(
                  onPressed: _completeSession,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
    ],
    ),
    ),
    ),
    ),
    );
  }
}