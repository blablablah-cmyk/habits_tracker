import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  // Make this a singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Create plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize iOS settings
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Initialize settings
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsIOS);

      // Initialize plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification received: ${details.payload}');
        },
      );

      _initialized = true;
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _initialized = false;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (!await _ensureInitialized()) return false;
    
    try {
      // Request Android 13+ notification permission
      final android = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        print(granted != null && granted 
            ? '✅ Android notification permission granted' 
            : '⚠️ Android notification permission denied');
        return granted ?? false;
      }

      // Request iOS permissions
      final ios = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print(granted != null && granted 
            ? '✅ iOS notification permission granted' 
            : '⚠️ iOS notification permission denied');
        return granted ?? false;
      }

      return true; // Default to true for other platforms
    } catch (e) {
      print('⚠️ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Schedule notifications for a habit
  Future<void> scheduleHabitNotifications(Habit habit) async {
    if (!habit.enableNotifications) {
      print('ℹ️ Notifications disabled for habit: ${habit.name}');
      return;
    }

    if (!await _ensureInitialized()) {
      print('⚠️ Cannot schedule notifications - service not initialized');
      return;
    }

    try {
      // Cancel existing notifications for this habit first
      await cancelHabitNotifications(habit.id);

      if (habit.frequency == HabitFrequency.timed && habit.startTime != null) {
        await _scheduleTimedHabitNotifications(habit);
      } else {
        await _scheduleRegularHabitNotification(habit);
      }

      print('✅ Scheduled notifications for habit: ${habit.name}');
    } catch (e) {
      print('⚠️ Error scheduling notifications for ${habit.name}: $e');
    }
  }

  /// Schedule notifications for timed habits
  Future<void> _scheduleTimedHabitNotifications(Habit habit) async {
    final now = DateTime.now();
    
    // Determine which days to schedule for
    final daysToSchedule = habit.customDays.isEmpty 
        ? List.generate(7, (index) => index) // All days if no custom days
        : habit.customDays;

    for (final dayOffset in daysToSchedule) {
      for (final minutesBefore in habit.notificationOffsets) {
        await _scheduleNotificationForDay(
          habit: habit,
          dayOfWeek: dayOffset,
          minutesBefore: minutesBefore,
        );
      }
    }
  }

  /// Schedule a single notification for a specific day
  Future<void> _scheduleNotificationForDay({
    required Habit habit,
    required int dayOfWeek,
    required int minutesBefore,
  }) async {
    if (flutterLocalNotificationsPlugin == null) return;
    
    try {
      final now = DateTime.now();
      final currentWeekday = now.weekday - 1; // Convert to 0-6
      
      // Calculate target date
      int daysUntilTarget = (dayOfWeek - currentWeekday) % 7;
      if (daysUntilTarget == 0 && now.hour > habit.startTime!.hour) {
        daysUntilTarget = 7; // Schedule for next week if time has passed
      }
      
      final targetDate = now.add(Duration(days: daysUntilTarget));
      final notificationTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        habit.startTime!.hour,
        habit.startTime!.minute - minutesBefore,
      );

      // Skip if notification time is in the past
      if (notificationTime.isBefore(now)) {
        return;
      }

      final notificationId = _getNotificationId(habit.id, dayOfWeek, minutesBefore);
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '⏰ ${habit.name}',
        'Starting in $minutesBefore minutes',
        tz.TZDateTime.from(notificationTime, tz.local),
        _notificationDetails(habit),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: habit.id,
      );

      print('📅 Scheduled: ${habit.name} for ${_getDayName(dayOfWeek)} at ${_formatNotificationTime(notificationTime)}');
    } catch (e) {
      print('⚠️ Error scheduling notification for day $dayOfWeek: $e');
    }
  }

  /// Schedule regular daily reminder (non-timed habits)
  Future<void> _scheduleRegularHabitNotification(Habit habit) async {
    if (flutterLocalNotificationsPlugin == null) return;
    
    try {
      final now = DateTime.now();
      var reminderTime = DateTime(now.year, now.month, now.day, 9, 0); // 9 AM
      
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(Duration(days: 1));
      }

      final notificationId = _getNotificationId(habit.id, 0, 0);
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '📝 ${habit.name}',
        'Don\'t forget your daily habit!',
        tz.TZDateTime.from(reminderTime, tz.local),
        _notificationDetails(habit),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: habit.id,
      );

      print('📅 Scheduled daily reminder for ${habit.name} at 9:00 AM');
    } catch (e) {
      print('⚠️ Error scheduling daily reminder for ${habit.name}: $e');
    }
  }

  /// Get notification details based on habit
  NotificationDetails _notificationDetails(Habit habit) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Notifications for your habits',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        color: habit.color,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Cancel all notifications for a specific habit
  Future<void> cancelHabitNotifications(String habitId) async {
    if (!await _ensureInitialized()) return;
    
    try {
      // Cancel for all days and all offset combinations
      for (int day = 0; day < 7; day++) {
        for (int offset in [5, 10, 15, 30, 60]) {
          final notificationId = _getNotificationId(habitId, day, offset);
          await flutterLocalNotificationsPlugin.cancel(notificationId);
        }
      }
      
      // Cancel the regular daily notification
      await flutterLocalNotificationsPlugin.cancel(_getNotificationId(habitId, 0, 0));
      
      print('🗑️ Cancelled notifications for habit: $habitId');
    } catch (e) {
      print('⚠️ Error canceling notifications for $habitId: $e');
    }
  }

  /// Schedule notifications for all habits
  Future<void> scheduleAllHabitNotifications(List<Habit> habits) async {
    if (!await _ensureInitialized()) {
      print('⚠️ Cannot schedule notifications - service not initialized');
      return;
    }
    
    try {
      for (final habit in habits) {
        if (habit.enableNotifications && habit.isActive) {
          await scheduleHabitNotifications(habit);
        }
      }
      
      print('✅ Scheduled notifications for ${habits.length} habits');
    } catch (e) {
      print('⚠️ Error scheduling all notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!await _ensureInitialized()) return;
    
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('🗑️ Cancelled all notifications');
    } catch (e) {
      print('⚠️ Error canceling all notifications: $e');
    }
  }

  /// Send immediate test notification
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await _ensureInitialized()) {
      print('⚠️ Cannot send notification - service not initialized');
      return;
    }
    
    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            'Test Notifications',
            channelDescription: 'Test notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      
      print('✅ Sent immediate notification: $title');
    } catch (e) {
      print('⚠️ Error sending immediate notification: $e');
    }
  }

  /// Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!await _ensureInitialized()) return [];
    
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('⚠️ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Generate unique notification ID
  int _getNotificationId(String habitId, int dayOfWeek, int minutesBefore) {
    final baseId = habitId.hashCode & 0x7FFFFFFF; // Ensure positive
    return (baseId % 100000) + (dayOfWeek * 1000) + minutesBefore;
  }

  /// Ensure service is initialized (returns false if initialization failed)
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    
    await initialize();
    return _initialized;
  }

  /// Helper: Get day name
  String _getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day];
  }

  /// Helper: Format notification time
  String _formatNotificationTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Check if notifications are available
  bool get isAvailable => _initialized;

  // Test notification method
  Future<void> showTestNotification() async {
    if (!_initialized) {
      debugPrint('⚠️ Notifications not initialized');
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.show(
        0, // notification id
        'Test Notification', 
        'This is a test notification from Habits Tracker',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel', // channel id
            'Test Channel', // channel name
            channelDescription: 'Channel for test notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('⚠️ Error showing test notification: $e');
    }
  }
}