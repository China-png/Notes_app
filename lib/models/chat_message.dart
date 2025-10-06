import 'package:isar/isar.dart';

part 'chat_message.g.dart';

// Модель сообщения в чате
@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  // ID сессии, к которой относится сообщение
  @Index()
  late int sessionId;

  // Текст сообщения
  late String content;

  // Отправитель: 'user' или 'ai'
  late String sender;

  // Время отправки
  @Index()
  late DateTime timestamp;

  // Токены использованные (для статистики)
  int? tokensUsed;

  ChatMessage({
    this.id = Isar.autoIncrement,
    required this.sessionId,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.tokensUsed,
  });
}