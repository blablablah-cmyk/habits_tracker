import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // timezone initialization
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to specific habit
    print('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();
    
    return await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission() ?? true;
  }

  Future<void> scheduleHabitNotifications(Habit habit) async {
    if (!habit.enableNotifications || !habit.shouldBeDoneToday()) return;
    
    await cancelHabitNotifications(habit.id);

    if (habit.frequency == HabitFrequency.timed && habit.startTime != null) {
      await _scheduleTimedHabitNotifications(habit);
    } else {
      await _scheduleRegularHabitNotification(habit);
    }
  }

  Future<void> _scheduleTimedHabitNotifications(Habit habit) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final offset in habit.notificationOffsets) {
      final notificationTime = today.add(Duration(
        hours: habit.startTime!.hour,
        minutes: habit.startTime!.minute - offset,
      ));

      if (notificationTime.isAfter(now)) {
        await _scheduleNotification(
          id: _getNotificationId(habit.id, offset),
          title: 'Habit Reminder',
          body: '${habit.name} starts in $offset minutes${habit.timeRangeString != null ? ' (${habit.timeRangeString})' : ''}',
          scheduledDate: notificationTime,
          payload: habit.id,
        );
      }
    }
  }

  Future<void> _scheduleRegularHabitNotification(Habit habit) async {
    // For non-timed habits, send a daily reminder at 9 AM
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 9, 0);
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(Duration(days: 1));
    }

    await _scheduleNotification(
      id: _getNotificationId(habit.id, 0),
      title: 'Daily Habit Reminder',
      body: 'Don\'t forget to complete: ${habit.name}',
      scheduledDate: reminderTime,
      payload: habit.id,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleAllHabitNotifications(List<Habit> habits) async {
    for (final habit in habits) {
      await scheduleHabitNotifications(habit);
    }
  }

  Future<void> cancelHabitNotifications(String habitId) async {
      try {
      await initialize();  // ensures plugin is ready
      final baseId = habitId.hashCode;
      for (int i = 0; i < 10; i++) {
        await _notifications.cancel(baseId + i);
      }
      } catch (e, st) {
      print("Cancel failed (likely plugin not ready yet): $e\n$st");
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  int _getNotificationId(String habitId, int offset) {
    return habitId.hashCode + offset;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Send immediate notification (for testing or instant reminders)
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}