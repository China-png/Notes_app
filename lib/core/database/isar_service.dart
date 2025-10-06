import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/note.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  // Singleton pattern
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  // Получить экземпляр Isar
  Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }

  // Инициализация БД
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();

    return await Isar.open(
      [
        NoteSchema,
        ChatMessageSchema,
        ChatSessionSchema,
      ],
      directory: dir.path,
      name: 'notes_ai_db',
      inspector: true, // Включает Isar Inspector для отладки
    );
  }

  // Закрыть БД (обычно при закрытии приложения)
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  // Очистить все данные (для тестирования)
  Future<void> clearAllData() async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.clear();
    });
  }
}