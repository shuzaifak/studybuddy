class Note {
  final int? id;
  final String title;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? subject;

  Note({
    this.id,
    required this.title,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
  });

  Note copy({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subject,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        subject: subject ?? this.subject,
      );

  static Note fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as int?,
    title: map['title'] as String,
    content: map['content'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    subject: map['subject'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'subject': subject,
  };
}