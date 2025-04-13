import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedFocusDuration = '25';
  String _selectedBreakDuration = '5';
  bool _autoStartBreaks = true;
  bool _autoStartPomodoros = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedFocusDuration = prefs.getString('focus_duration') ?? '25';
      _selectedBreakDuration = prefs.getString('break_duration') ?? '5';
      _autoStartBreaks = prefs.getBool('auto_start_breaks') ?? true;
      _autoStartPomodoros = prefs.getBool('auto_start_pomodoros') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('focus_duration', _selectedFocusDuration);
    await prefs.setString('break_duration', _selectedBreakDuration);
    await prefs.setBool('auto_start_breaks', _autoStartBreaks);
    await prefs.setBool('auto_start_pomodoros', _autoStartPomodoros);
  }

  Future<void> _requestNotificationPermissions() async {
    // For Android
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        return;
      }
    }

    // For iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          _buildSectionHeader('Appearance', Icons.palette_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications section
          _buildSectionHeader('Notifications', Icons.notifications_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive reminders for upcoming tasks'),
                  secondary: Icon(
                    _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: theme.colorScheme.primary,
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await _requestNotificationPermissions();
                    }
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    await _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Timer section
          _buildSectionHeader('Timer Settings', Icons.timer_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Focus Duration'),
                  subtitle: const Text('Set the length of your focus sessions'),
                  trailing: DropdownButton<String>(
                    value: _selectedFocusDuration,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFocusDuration = newValue;
                        });
                        _saveSettings();
                      }
                    },
                    items: <String>['15', '20', '25', '30', '45', '60']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('$value min'),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  title: const Text('Break Duration'),
                  subtitle: const Text('Set the length of your breaks'),
                  trailing: DropdownButton<String>(
                    value: _selectedBreakDuration,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBreakDuration = newValue;
                        });
                        _saveSettings();
                      }
                    },
                    items: <String>['3', '5', '10', '15']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('$value min'),
                      );
                    }).toList(),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Auto-start Breaks'),
                  subtitle: const Text('Automatically start breaks when focus sessions end'),
                  value: _autoStartBreaks,
                  onChanged: (value) {
                    setState(() {
                      _autoStartBreaks = value;
                    });
                    _saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-start Pomodoros'),
                  subtitle: const Text('Automatically start new focus sessions after breaks'),
                  value: _autoStartPomodoros,
                  onChanged: (value) {
                    setState(() {
                      _autoStartPomodoros = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About section
          _buildSectionHeader('About', Icons.info_outline),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('App Version'),
                  subtitle: const Text('StudyBuddy v1.0.0'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: const Text('Send Feedback'),
                  subtitle: const Text('Help us improve StudyBuddy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback option will be available in the next update!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data management section
          _buildSectionHeader('Data Management', Icons.storage_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all tasks, sessions, and notes'),
                  trailing: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: () {
                    _showClearDataDialog(context);
                  },
                ),
                ListTile(
                  title: const Text('Export Data'),
                  subtitle: const Text('Save your data as a backup file'),
                  trailing: const Icon(Icons.download, color: Colors.blue),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export feature will be available in the next update!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to clear all data?'),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone and will delete all of your tasks, study sessions, and notes.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear Data', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Reset database
                _clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been cleared'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData() async {
    // Here you would typically clear your database
    // For demonstration, we'll just show a message
    // In a real app, you would implement this to delete all records
    // from your SQLite database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This would clear all data in a real app.'),
      ),
    );
  }
}