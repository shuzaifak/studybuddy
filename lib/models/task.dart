class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int priority;
  final bool isCompleted;
  final String? category;
  final DateTime? reminderTime;

  Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 0,
    this.isCompleted = false,
    this.category,
    this.reminderTime,
  });

  Task copy({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
    bool? isCompleted,
    String? category,
    DateTime? reminderTime,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        category: category ?? this.category,
        reminderTime: reminderTime ?? this.reminderTime,
      );

  static Task fromMap(Map<String, dynamic> map) => Task(
    id: map['id'] as int?,
    title: map['title'] as String,
    description: map['description'] as String?,
    dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
    priority: map['priority'] as int,
    isCompleted: map['is_completed'] == 1,
    category: map['category'] as String?,
    reminderTime: map['reminder_time'] != null ? DateTime.parse(map['reminder_time'] as String) : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'priority': priority,
    'is_completed': isCompleted ? 1 : 0,
    'category': category,
    'reminder_time': reminderTime?.toIso8601String(),
  };
}