import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isInit = false;
  String _searchQuery = '';
  String _selectedSubject = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      Provider.of<NoteProvider>(context, listen: false).loadNotes();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorScreen(isEditing: false),
      ),
    );
  }

  List<Note> _getFilteredNotes(List<Note> notes) {
    return notes.where((note) {
      // Filter by subject
      if (_selectedSubject != 'All' && note.subject != _selectedSubject) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return note.title.toLowerCase().contains(query) ||
            (note.content?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final theme = Theme.of(context);
    final filteredNotes = _getFilteredNotes(noteProvider.notes);

    // Get unique subjects for the filter
    final subjects = ['All'];
    for (final note in noteProvider.notes) {
      if (note.subject != null && !subjects.contains(note.subject)) {
        subjects.add(note.subject!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Notes'),
                  content: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter search term',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedSubject = value;
              });
            },
            itemBuilder: (context) {
              return subjects.map((subject) {
                return PopupMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: noteProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredNotes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No notes found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add a new note',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: filteredNotes.length,
        itemBuilder: (ctx, index) {
          final note = filteredNotes[index];
          return NoteCard(
            note: note,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    isEditing: true,
                    note: note,
                  ),
                ),
              );
            },
            onDelete: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Note'),
                  content: const Text('Are you sure you want to delete this note?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                noteProvider.deleteNote(note.id!);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorsBySubject = {
      'Math': Colors.blue,
      'Science': Colors.green,
      'History': Colors.orange,
      'English': Colors.purple,
      'Computer Science': Colors.teal,
    };

    final cardColor = note.subject != null && colorsBySubject.containsKey(note.subject)
        ? colorsBySubject[note.subject]!.withOpacity(0.2)
        : theme.colorScheme.primary.withOpacity(0.1);

    return Card(
      color: cardColor,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content ?? '',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (note.subject != null)
                    Chip(
                      label: Text(
                        note.subject!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      visualDensity: VisualDensity.compact,
                    ),
                  Spacer(),
                  Text(
                    DateFormat('MMM d').format(note.updatedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final bool isEditing;
  final Note? note;

  const NoteEditorScreen({
    Key? key,
    required this.isEditing,
    this.note,
  }) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedSubject;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedSubject = widget.note?.subject;

    // Listen for changes to track if the note has been edited
    _titleController.addListener(_markAsEdited);
    _contentController.addListener(_markAsEdited);
  }

  void _markAsEdited() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final now = DateTime.now();

    if (widget.isEditing && widget.note != null) {
      final updatedNote = widget.note!.copy(
        title: _titleController.text,
        content: _contentController.text,
        updatedAt: now,
        subject: _selectedSubject,
      );
      noteProvider.updateNote(updatedNote);
    } else {
      final newNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        createdAt: now,
        updatedAt: now,
        subject: _selectedSubject,
      );
      noteProvider.addNote(newNote);
    }

    Navigator.of(context).pop();
  }

  Future<bool> _onWillPop() async {
    if (!_isEdited) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Edit Note' : 'New Note',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            DropdownButton<String?>(
              value: _selectedSubject,
              hint: const Text('Subject'),
              icon: const Icon(Icons.arrow_drop_down),
              underline: Container(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubject = newValue;
                  _markAsEdited();
                });
              },
              items: <String?>[
                null,
                'Math',
                'Science',
                'History',
                'English',
                'Computer Science',
                'Other'
              ].map<DropdownMenuItem<String?>>((String? value) {
                return DropdownMenuItem<String?>(
                  value: value,
                  child: Text(value ?? 'No Subject'),
                );
              }).toList(),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Start typing your note...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}