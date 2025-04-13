import 'package:flutter/foundation.dart';
import '../models/study_session.dart';
import '../data/database_helper.dart';
import 'package:intl/intl.dart';

class StudySessionProvider with ChangeNotifier {
  List<StudySession> _sessions = [];
  bool _isLoading = false;

  List<StudySession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await DatabaseHelper.instance.readAllStudySessions();
    } catch (e) {
      debugPrint('Error loading study sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionsByDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      _sessions = await DatabaseHelper.instance.readStudySessionsByDate(formattedDate);
    } catch (e) {
      debugPrint('Error loading study sessions by date: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StudySession> addSession(StudySession session) async {
    final newSession = await DatabaseHelper.instance.createStudySession(session);
    _sessions.add(newSession);
    _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    notifyListeners();
    return newSession;
  }

  int getTotalStudyTimeToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySessions = _sessions.where((session) => session.date == today);
    return todaySessions.fold(0, (sum, session) => sum + session.duration);
  }

  Map<String, int> getStudyTimeBySubject() {
    final Map<String, int> subjectTimes = {};
    for (final session in _sessions) {
      if (subjectTimes.containsKey(session.subject)) {
        subjectTimes[session.subject] = subjectTimes[session.subject]! + session.duration;
      } else {
        subjectTimes[session.subject] = session.duration;
      }
    }
    return subjectTimes;
  }

  Map<String, int> getStudyTimeByDay() {
    final Map<String, int> dayTimes = {};
    for (final session in _sessions) {
      if (dayTimes.containsKey(session.date)) {
        dayTimes[session.date] = dayTimes[session.date]! + session.duration;
      } else {
        dayTimes[session.date] = session.duration;
      }
    }
    return dayTimes;
  }
}