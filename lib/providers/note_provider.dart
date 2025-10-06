import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

// Провайдер репозитория
final noteRepositoryProvider = Provider((ref) => NoteRepository());

// Провайдер списка всех заметок (Stream)
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.watchAllNotes();
});

// Провайдер для конкретной заметки
final noteByIdProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getNoteById(id);
});

// Провайдер для поиска
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final repository = ref.watch(noteRepositoryProvider);
  return await repository.searchNotes(query);
});

// Провайдер избранных заметок
final favoriteNotesProvider = FutureProvider<List<Note>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return await repository.getFavoriteNotes();
});

// Контроллер для операций с заметками
class NoteController extends StateNotifier<AsyncValue<void>> {
  final NoteRepository _repository;

  NoteController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createNote(Note note) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createNote(note);
    });
  }

  Future<void> updateNote(Note note) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateNote(note);
    });
  }

  Future<void> deleteNote(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteNote(id);
    });
  }

  Future<void> togglePin(int id) async {
    await _repository.togglePin(id);
  }

  Future<void> toggleFavorite(int id) async {
    await _repository.toggleFavorite(id);
  }
}

final noteControllerProvider =
StateNotifierProvider<NoteController, AsyncValue<void>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteController(repository);
});