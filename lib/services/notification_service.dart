class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  
  factory NotificationService() => instance;
  NotificationService._internal();

  bool _initialized = false;

  // Initialize - safe, does nothing if notifications not available
  Future<void> initialize() async {
    if (_initialized) return;
    // TODO: Add flutter_local_notifications setup here when ready
    _initialized = true;
    print('NotificationService initialized (stub)');
  }

  // Request permission - always returns true for now
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    print('Notification permission requested (stub)');
    return true;
  }

  // Schedule notifications - safe stub
  Future<void> scheduleHabitNotifications(dynamic habit) async {
    await _ensureInitialized();
    print('Would schedule notifications for: ${habit.name}');
    // TODO: Implement actual scheduling
  }

  // Cancel notifications - safe stub with proper error handling
  Future<void> cancelHabitNotifications(String habitId) async {
    try {
      await _ensureInitialized();
      print('Would cancel notifications for habit: $habitId');
      // TODO: Implement actual canceling
      // For now, just simulate the cancellation without actual flutter_local_notifications
      final baseId = habitId.hashCode;
      for (int i = 0; i < 10; i++) {
        // await _notifications.cancel(baseId + i); // This would be the real implementation
        print('Would cancel notification ID: ${baseId + i}');
      }
    } catch (e) {
      print('Error canceling notifications for $habitId: $e');
      // Don't rethrow - we don't want to break habit deletion if notifications fail
    }
  }

  // Schedule all - safe stub
  Future<void> scheduleAllHabitNotifications(List<dynamic> habits) async {
    try {
      await _ensureInitialized();
      print('Would schedule notifications for ${habits.length} habits');
      // TODO: Implement batch scheduling
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  // Cancel all - safe stub
  Future<void> cancelAllNotifications() async {
    try {
      await _ensureInitialized();
      print('Would cancel all notifications');
      // TODO: Implement cancel all
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  // Send test notification - safe stub
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _ensureInitialized();
      print('Test notification: $title - $body');
      // TODO: Send actual notification
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Ensure the service is initialized before any operation
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}