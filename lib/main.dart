import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const NotesScreen(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  DateTime dateTime;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'dateTime': dateTime.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    dateTime: DateTime.parse(json['dateTime']),
  );
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('notes') ?? '[]';
    final List<dynamic> decoded = json.decode(notesJson);
    setState(() {
      _notes.clear();
      _notes.addAll(decoded.map((e) => Note.fromJson(e)).toList());
      _notes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = json.encode(_notes.map((e) => e.toJson()).toList());
    await prefs.setString('notes', notesJson);
  }

  void _addOrEditNote({Note? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          onSave: (title, content) {
            setState(() {
              if (note == null) {
                _notes.add(Note(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  content: content,
                  dateTime: DateTime.now(),
                ));
              } else {
                note.title = title;
                note.content = content;
                note.dateTime = DateTime.now();
              }
              _notes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
            });
            _saveNotes();
          },
        ),
      ),
    );
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Заметки'),
        elevation: 2,
      ),
      body: _notes.isEmpty
          ? const Center(
        child: Text(
          'Нет заметок\nНажмите + чтобы создать',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _notes.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(
                note.title.isEmpty ? 'Без названия' : note.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(note.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              onTap: () => _addOrEditNote(note: note),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить заметку?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteNote(note);
                            Navigator.pop(context);
                          },
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Сегодня ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дней назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Function(String title, String content) onSave;

  const NoteEditorScreen({
    Key? key,
    this.note,
    required this.onSave,
  }) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    widget.onSave(_titleController.text, _contentController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Новая заметка' : 'Редактировать'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Заголовок',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Начните писать...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}