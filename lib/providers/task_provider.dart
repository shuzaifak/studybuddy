import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';
import '../data/database_helper.dart';
import '../main.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  // Initialize timezone database
  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    tz.initializeTimeZones();
    await loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;

      // Delay notification until after build phase
      Future.microtask(() => notifyListeners());

      _tasks = await DatabaseHelper.instance.readAllTasks();
      _sortTasks();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load tasks: ${e.toString()}';
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      // Sort by completion status first (incomplete first)
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Then by due date (earlier first)
      return (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999));
    });
  }

  Future<Task> addTask(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newTask = await DatabaseHelper.instance.createTask(task);
      _tasks.add(newTask);
      _sortTasks();

      if (task.reminderTime != null) {
        await _scheduleTaskNotification(newTask);
      }

      return newTask;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to add task: ${e.toString()}';
      debugPrint('Error adding task: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();

      await DatabaseHelper.instance.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        await _cancelTaskNotification(task.id!);
        if (task.reminderTime != null && !task.isCompleted) {
          await _scheduleTaskNotification(task);
        }
        _sortTasks();
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to update task: ${e.toString()}';
      debugPrint('Error updating task: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        final task = _tasks[index];
        final updatedTask = task.copy(isCompleted: !task.isCompleted);
        await DatabaseHelper.instance.updateTask(updatedTask);
        _tasks[index] = updatedTask;

        if (updatedTask.isCompleted) {
          await _cancelTaskNotification(id);
        } else if (updatedTask.reminderTime != null) {
          await _scheduleTaskNotification(updatedTask);
        }
        _sortTasks();
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to toggle task: ${e.toString()}';
      debugPrint('Error toggling task completion: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await DatabaseHelper.instance.deleteTask(id);
      _tasks.removeWhere((task) => task.id == id);
      await _cancelTaskNotification(id);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete task: ${e.toString()}';
      debugPrint('Error deleting task: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleTaskNotification(Task task) async {
    if (task.id == null || task.reminderTime == null || task.isCompleted) return;

    try {
      final scheduledTime = tz.TZDateTime.from(task.reminderTime!, tz.local);

      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Notifications for task reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!,
        'Task Reminder: ${task.title}',
        task.description?.isNotEmpty == true
            ? task.description!
            : 'It\'s time to complete this task!',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Removed the deprecated parameter
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelTaskNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<void> rescheduleAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      for (final task in _tasks) {
        if (task.reminderTime != null && !task.isCompleted) {
          await _scheduleTaskNotification(task);
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }
}