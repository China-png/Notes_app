import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/note.dart';
import '../../providers/note_provider.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isModified = true;
    });
  }

  @override
  void dispose() {
    _saveNote();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_isModified) return;

    final updatedNote = widget.note.copyWith(
      title: _titleController.text.isEmpty ? 'Без названия' : _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );

    await ref.read(noteControllerProvider.notifier).updateNote(updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await _saveNote();
            if (mounted) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.note.isFavorite ? Icons.star : Icons.star_border,
              color: widget.note.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              ref.read(noteControllerProvider.notifier).toggleFavorite(widget.note.id);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'share':
                // Реализовать шаринг
                  break;
                case 'delete':
                  _confirmDelete();
                  break;
                case 'color':
                  _showColorPicker();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'color',
                child: Row(
                  children: [
                    Icon(Icons.palette),
                    SizedBox(width: 8),
                    Text('Цвет'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Поделиться'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: widget.note.colorCode != null
            ? Color(widget.note.colorCode!).withOpacity(0.1)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Заголовок',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Начните писать...',
                    border: InputBorder.none,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isModified
          ? Container(
        padding: const EdgeInsets.all(8),
        color: Colors.blue[50],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save, size: 16),
            const SizedBox(width: 8),
            Text(
              'Изменения сохранятся автоматически',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      )
          : null,
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(noteControllerProvider.notifier).deleteNote(widget.note.id);
              if (mounted) {
                Navigator.pop(context); // Закрыть диалог
                Navigator.pop(context); // Вернуться на главный экран
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      null, // Без цвета
      Colors.red[100]!.value,
      Colors.orange[100]!.value,
      Colors.yellow[100]!.value,
      Colors.green[100]!.value,
      Colors.blue[100]!.value,
      Colors.purple[100]!.value,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((colorValue) {
            return InkWell(
              onTap: () async {
                final updatedNote = widget.note.copyWith(colorCode: colorValue);
                await ref.read(noteControllerProvider.notifier).updateNote(updatedNote);
                if (mounted) Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorValue != null ? Color(colorValue) : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.note.colorCode == colorValue
                        ? Colors.blue
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: colorValue == null
                    ? const Icon(Icons.close)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}