import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';

class AIService {
  late GenerativeModel _model;
  static const String _apiKey = 'AIzaSyCbNniLgMcfYw5SsKg-7uu_EZMhmj9VSBI';

  AIService() {
    // Попробуйте эти модели по порядку, если одна не работает:
    // 'gemini-pro' - старая стабильная
    // 'gemini-1.5-flash' - новая быстрая
    // 'gemini-1.5-pro' - новая мощная

    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite', // Используем старую проверенную версию
      apiKey: _apiKey,
    );
  }

  // Отправить сообщение и получить ответ
  Future<String> sendMessage(String message, List<ChatMessage> history) async {
    try {
      // Конвертировать историю в формат Gemini
      final chatHistory = <Content>[];

      for (var msg in history) {
        chatHistory.add(Content(
          msg.sender == 'user' ? 'user' : 'model',
          [TextPart(msg.content)],
        ));
      }

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
      final chatHistory = <Content>[];

      for (var msg in history) {
        chatHistory.add(Content(
          msg.sender == 'user' ? 'user' : 'model',
          [TextPart(msg.content)],
        ));
      }

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

  // Проверка доступных моделей и вывод списка
  Future<String> listAvailableModels() async {
    final modelsToTest = [
      'gemini-pro',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-1.0-pro',
      'gemini-2.0-flash-exp',
      'gemini-2.0-flash-live',
      'gemini-2.5-flash-native-audio-dialog',
      'gemini-2.5-flash-live',
      'learnlm-2.0-flash-experimental',
      'gemini-robotics-er-1.5-preview',
      'gemini-2.5-flash-tts',
      'gemini-2.0-flash',
      'gemini-2.0-flash-preview-image-generation',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash-lite',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
    ];

    String result = 'Проверка доступных моделей:\n\n';

    for (var modelName in modelsToTest) {
      try {
        final testModel = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
        );

        final response = await testModel.generateContent([
          Content.text('Ответь одним словом: привет')
        ]);

        if (response.text != null && response.text!.isNotEmpty) {
          result += '✅ $modelName - РАБОТАЕТ\n';
          result += '   Ответ: ${response.text}\n\n';
        } else {
          result += '❌ $modelName - Пустой ответ\n\n';
        }
      } catch (e) {
        result += '❌ $modelName - ОШИБКА\n';
        result += '   ${e.toString()}\n\n';
      }
    }

    return result;
  }
}