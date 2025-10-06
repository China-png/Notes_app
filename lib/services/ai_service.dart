import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';

class AIService {
  late GenerativeModel _model;
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // Получить на ai.google.dev

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  // Отправить сообщение и получить ответ
  Future<String> sendMessage(String message, List<ChatMessage> history) async {
    try {
      // Конвертировать историю в формат Gemini
      final chatHistory = history.map((msg) {
        return Content.text(msg.content);
      }).toList();

      // Создать чат с историей
      final chat = _model.startChat(history: chatHistory);

      // Отправить сообщение
      final response = await chat.sendMessage(Content.text(message));

      return response.text ?? 'Не удалось получить ответ';
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  // Стриминг ответа (для печатающегося эффекта)
  Stream<String> sendMessageStream(String message, List<ChatMessage> history) async* {
    try {
      final chatHistory = history.map((msg) {
        return Content.text(msg.content);
      }).toList();

      final chat = _model.startChat(history: chatHistory);
      final response = chat.sendMessageStream(Content.text(message));

      await for (final chunk in response) {
        yield chunk.text ?? '';
      }
    } catch (e) {
      yield 'Ошибка: $e';
    }
  }

  // Генерация заголовка для заметки на основе контента
  Future<String> generateNoteTitle(String content) async {
    try {
      final prompt = '''
На основе следующего текста создай короткий заголовок (максимум 50 символов):

$content

Ответь только заголовком, без дополнительного текста.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Без названия';
    } catch (e) {
      return 'Без названия';
    }
  }

  // Анализ заметки и предложение тегов
  Future<List<String>> suggestTags(String title, String content) async {
    try {
      final prompt = '''
Проанализируй следующую заметку и предложи 3-5 релевантных тегов на русском языке.

Заголовок: $title
Содержание: $content

Ответь только списком тегов через запятую, без дополнительного текста.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      return text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .take(5)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Суммаризация длинной заметки
  Future<String> summarizeNote(String content) async {
    try {
      final prompt = '''
Создай краткое резюме следующего текста (максимум 3 предложения):

$content
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Не удалось создать резюме';
    } catch (e) {
      return 'Ошибка при создании резюме';
    }
  }

  // Улучшение текста заметки
  Future<String> improveText(String content) async {
    try {
      final prompt = '''
Улучши следующий текст, исправив грамматические ошибки и улучшив стиль, 
но сохрани основной смысл и структуру:

$content
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? content;
    } catch (e) {
      return content;
    }
  }

  // Перевод текста
  Future<String> translateText(String content, String targetLanguage) async {
    try {
      final prompt = '''
Переведи следующий текст на $targetLanguage:

$content
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? content;
    } catch (e) {
      return content;
    }
  }
}