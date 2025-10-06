import 'package:isar/isar.dart';
import '../core/database/isar_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatRepository {
  final IsarService _isarService = IsarService.instance;

  // === СЕССИИ ===

  // Получить все сессии
  Future<List<ChatSession>> getAllSessions() async {
    final isar = await _isarService.isar;
    return await isar.chatSessions
        .where()
        .sortByIsPinnedDesc()
        .thenByLastMessageAtDesc()
        .findAll();
  }

  // Создать новую сессию
  Future<int> createSession(ChatSession session) async {
    final isar = await _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.chatSessions.put(session);
    });
  }

  // Получить сессию по ID
  Future<ChatSession?> getSessionById(int id) async {
    final isar = await _isarService.isar;
    return await isar.chatSessions.get(id);
  }

  // Обновить сессию
  Future<void> updateSession(ChatSession session) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      await isar.chatSessions.put(session);
    });
  }

  // Удалить сессию и все её сообщения
  Future<void> deleteSession(int sessionId) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      // Удалить все сообщения сессии
      await isar.chatMessages
          .filter()
          .sessionIdEqualTo(sessionId)
          .deleteAll();

      // Удалить саму сессию
      await isar.chatSessions.delete(sessionId);
    });
  }

  // === СООБЩЕНИЯ ===

  // Получить все сообщения сессии
  Future<List<ChatMessage>> getMessagesBySession(int sessionId) async {
    final isar = await _isarService.isar;
    return await isar.chatMessages
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestamp()
        .findAll();
  }

  // Добавить сообщение
  Future<int> addMessage(ChatMessage message) async {
    final isar = await _isarService.isar;

    return await isar.writeTxn(() async {
      // Сохранить сообщение
      final messageId = await isar.chatMessages.put(message);

      // Обновить время последнего сообщения в сессии
      final session = await isar.chatSessions.get(message.sessionId);
      if (session != null) {
        session.lastMessageAt = message.timestamp;

        // Если это первое сообщение, обновить заголовок
        if (session.title == 'Новый чат' && message.sender == 'user') {
          session.title = message.content.length > 30
              ? '${message.content.substring(0, 30)}...'
              : message.content;
        }

        await isar.chatSessions.put(session);
      }

      return messageId;
    });
  }

  // Удалить сообщение
  Future<bool> deleteMessage(int id) async {
    final isar = await _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.chatMessages.delete(id);
    });
  }

  // Stream сообщений для реактивного UI
  Stream<List<ChatMessage>> watchMessages(int sessionId) async* {
    final isar = await _isarService.isar;
    yield* isar.chatMessages
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestamp()
        .watch(fireImmediately: true);
  }

  // Stream сессий
  Stream<List<ChatSession>> watchSessions() async* {
    final isar = await _isarService.isar;
    yield* isar.chatSessions
        .where()
        .sortByIsPinnedDesc()
        .thenByLastMessageAtDesc()
        .watch(fireImmediately: true);
  }

  // Получить статистику
  Future<Map<String, int>> getStatistics() async {
    final isar = await _isarService.isar;

    final totalSessions = await isar.chatSessions.count();
    final totalMessages = await isar.chatMessages.count();

    final allMessages = await isar.chatMessages.where().findAll();
    final totalTokens = allMessages
        .where((m) => m.tokensUsed != null)
        .fold(0, (sum, m) => sum + m.tokensUsed!);

    return {
      'sessions': totalSessions,
      'messages': totalMessages,
      'tokens': totalTokens,
    };
  }
}