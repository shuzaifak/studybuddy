import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('study_buddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Tasks table
    await db.execute('''
    CREATE TABLE tasks (
      id $idType,
      title $textType,
      description TEXT,
      due_date TEXT,
      priority INTEGER,
      is_completed $boolType,
      category TEXT,
      reminder_time TEXT
    )
    ''');

    // Study sessions table
    await db.execute('''
    CREATE TABLE study_sessions (
      id $idType,
      subject $textType,
      start_time TEXT,
      end_time TEXT,
      duration $integerType,
      date TEXT
    )
    ''');

    // Notes table
    await db.execute('''
    CREATE TABLE notes (
      id $idType,
      title $textType,
      content TEXT,
      created_at TEXT,
      updated_at TEXT,
      subject TEXT
    )
    ''');
  }

  // Task CRUD operations
  Future<Task> createTask(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copy(id: id);
  }

  Future<Task> readTask(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      columns: ['id', 'title', 'description', 'due_date', 'priority', 'is_completed', 'category', 'reminder_time'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'due_date ASC');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Study Session CRUD operations
  Future<StudySession> createStudySession(StudySession session) async {
    final db = await instance.database;
    final id = await db.insert('study_sessions', session.toMap());
    return session.copy(id: id);
  }

  Future<List<StudySession>> readAllStudySessions() async {
    final db = await instance.database;
    final result = await db.query('study_sessions', orderBy: 'date DESC');
    return result.map((json) => StudySession.fromMap(json)).toList();
  }

  Future<List<StudySession>> readStudySessionsByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'study_sessions',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((json) => StudySession.fromMap(json)).toList();
  }

  // Note CRUD operations
  Future<Note> createNote(Note note) async {
    final db = await instance.database;
    final id = await db.insert('notes', note.toMap());
    return note.copy(id: id);
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'updated_at DESC');
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}