import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../data/database_helper.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotes() async {
    // Only proceed if not already loading
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;

    // Schedule notification for after build completes
    Future.microtask(() => notifyListeners());

    try {
      _notes = await DatabaseHelper.instance.readAllNotes();
      _sortNotes();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load notes: ${e.toString()}';
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortNotes() {
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<Note> addNote(Note note) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newNote = await DatabaseHelper.instance.createNote(note);
      _notes.add(newNote);
      _sortNotes();
      return newNote;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to add note: ${e.toString()}';
      debugPrint('Error adding note: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      _isLoading = true;
      notifyListeners();

      await DatabaseHelper.instance.updateNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        _sortNotes();
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to update note: ${e.toString()}';
      debugPrint('Error updating note: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await DatabaseHelper.instance.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete note: ${e.toString()}';
      debugPrint('Error deleting note: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Note> getNotesBySubject(String subject) {
    return _notes.where((note) => note.subject == subject).toList();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }
}