import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Инициализация timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Almaty')); // Для Казахстана

    // Настройки для Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  // Обработка нажатия на уведомление
  void _onNotificationTap(NotificationResponse response) {
    // Здесь можно обработать открытие заметки
    print('Notification tapped: ${response.payload}');
  }

  // Запрос разрешений
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Запланировать уведомление
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isInitialized) await initialize();

    // Проверить разрешения
    if (!await requestPermissions()) {
      throw Exception('Notifications permission not granted');
    }

    // Конвертировать в TZDateTime
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Детали для Android
    const androidDetails = AndroidNotificationDetails(
      'notes_reminders',
      'Напоминания о заметках',
      channelDescription: 'Уведомления для напоминаний о заметках',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // Детали для iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: id.toString(),
    );
  }

  // Отменить уведомление
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Получить список запланированных уведомлений
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Показать немедленное уведомление (для тестирования)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'notes_reminders',
      'Напоминания о заметках',
      channelDescription: 'Уведомления для напоминаний о заметках',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }
}