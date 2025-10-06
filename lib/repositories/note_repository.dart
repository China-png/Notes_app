import 'package:isar/isar.dart';
import '../core/database/isar_service.dart';
import '../models/note.dart';

class NoteRepository {
  final IsarService _isarService = IsarService.instance;

  // Получить все заметки
  Future<List<Note>> getAllNotes() async {
    final isar = await _isarService.isar;
    return await isar.notes
        .where()
        .sortByIsPinnedDesc() // Закрепленные первыми
        .thenByUpdatedAtDesc() // Затем по дате обновления
        .findAll();
  }

  // Получить заметку по ID
  Future<Note?> getNoteById(int id) async {
    final isar = await _isarService.isar;
    return await isar.notes.get(id);
  }

  // Создать заметку
  Future<int> createNote(Note note) async {
    final isar = await _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.notes.put(note);
    });
  }

  // Обновить заметку
  Future<void> updateNote(Note note) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      note.updatedAt = DateTime.now();
      await isar.notes.put(note);
    });
  }

  // Удалить заметку
  Future<bool> deleteNote(int id) async {
    final isar = await _isarService.isar;
    return await isar.writeTxn(() async {
      return await isar.notes.delete(id);
    });
  }

  // Поиск по заметкам
  Future<List<Note>> searchNotes(String query) async {
    final isar = await _isarService.isar;
    final lowerQuery = query.toLowerCase();

    return await isar.notes
        .filter()
        .titleContains(lowerQuery, caseSensitive: false)
        .or()
        .contentContains(lowerQuery, caseSensitive: false)
        .findAll();
  }

  // Получить избранные заметки
  Future<List<Note>> getFavoriteNotes() async {
    final isar = await _isarService.isar;
    return await isar.notes
        .filter()
        .isFavoriteEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  // Получить заметки по тегу
  Future<List<Note>> getNotesByTag(String tag) async {
    final isar = await _isarService.isar;
    return await isar.notes
        .filter()
        .tagsElementContains(tag, caseSensitive: false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  // Stream для реактивного обновления UI
  Stream<List<Note>> watchAllNotes() async* {
    final isar = await _isarService.isar;
    yield* isar.notes
        .where()
        .sortByIsPinnedDesc()
        .thenByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  // Переключить закрепление
  Future<void> togglePin(int id) async {
    final note = await getNoteById(id);
    if (note != null) {
      note.isPinned = !note.isPinned;
      await updateNote(note);
    }
  }

  // Переключить избранное
  Future<void> toggleFavorite(int id) async {
    final note = await getNoteById(id);
    if (note != null) {
      note.isFavorite = !note.isFavorite;
      await updateNote(note);
    }
  }
}