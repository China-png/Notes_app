import 'package:isar/isar.dart';

part 'chat_session.g.dart';

// Модель сессии чата
@collection
class ChatSession {
  Id id = Isar.autoIncrement;

  // Название сессии
  late String title;

  // Дата создания
  @Index()
  late DateTime createdAt;

  // Последнее обновление
  late DateTime lastMessageAt;

  // Связь с заметкой (опционально)
  int? relatedNoteId;

  // Системный промпт для контекста
  String? systemPrompt;

  // Закреплена ли сессия
  bool isPinned = false;

  ChatSession({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.relatedNoteId,
    this.systemPrompt,
    this.isPinned = false,
  });

  // Метод для копирования с изменениями
  ChatSession copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    int? relatedNoteId,
    String? systemPrompt,
    bool? isPinned,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      relatedNoteId: relatedNoteId ?? this.relatedNoteId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}