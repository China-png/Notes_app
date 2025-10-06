import 'package:isar/isar.dart';

part 'note.g.dart'; // Будет сгенерирован build_runner

@collection
class Note {
  Id id = Isar.autoIncrement; // Автоинкремент ID

  @Index(type: IndexType.value) // Индекс для быстрого поиска
  late String title;

  late String content;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  // Теги для категоризации
  List<String> tags = [];

  // Цвет для визуального разделения
  int? colorCode;

  // Закреплена ли заметка
  bool isPinned = false;

  // Добавлена ли в избранное
  bool isFavorite = false;

  Note({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.colorCode,
    this.isPinned = false,
    this.isFavorite = false,
  });

  // Копирование с изменениями
  Note copyWith({
    Id? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? colorCode,
    bool? isPinned,
    bool? isFavorite,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      colorCode: colorCode ?? this.colorCode,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}