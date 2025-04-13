class StudySession {
  final int? id;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in minutes
  final String date;

  StudySession({
    this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.date,
  });

  StudySession copy({
    int? id,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? date,
  }) =>
      StudySession(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        duration: duration ?? this.duration,
        date: date ?? this.date,
      );

  static StudySession fromMap(Map<String, dynamic> map) => StudySession(
    id: map['id'] as int?,
    subject: map['subject'] as String,
    startTime: DateTime.parse(map['start_time'] as String),
    endTime: DateTime.parse(map['end_time'] as String),
    duration: map['duration'] as int,
    date: map['date'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject': subject,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'duration': duration,
    'date': date,
  };
}