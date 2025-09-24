import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/habit.dart';
import '../services/notification_service.dart';

class HabitsProvider with ChangeNotifier {
  List<Habit> _habits = [];
  late SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();

  HabitsProvider() {
    _loadHabits();
  }

  List<Habit> get habits => _habits;
  
  List<Habit> get activeHabits => _habits.where((habit) => habit.isActive).toList();
  
  List<Habit> get todayHabits => activeHabits.where((habit) => habit.shouldBeDoneToday()).toList();
  
  List<Habit> get completedTodayHabits => todayHabits.where((habit) => habit.isCompletedToday).toList();
  
  List<Habit> get pendingTodayHabits => todayHabits.where((habit) => !habit.isCompletedToday).toList();

  // NEW: Get timed habits
  List<Habit> get timedHabits => activeHabits.where((habit) => habit.frequency == HabitFrequency.timed).toList();
  
  List<Habit> get currentTimedHabits => timedHabits.where((habit) => habit.isInTimeWindow).toList();

  // Get habit by ID - SAFER APPROACH
  Habit? getHabitById(String id) {
    // Use where().firstOrNull instead of firstWhere to avoid StateError
    final matchingHabits = _habits.where((habit) => habit.id == id);
    return matchingHabits.isNotEmpty ? matchingHabits.first : null;
  }

  // Add new habit - ASYNC for notifications
  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    await _saveHabits();
    // Only schedule notifications if enabled
    if (habit.enableNotifications) {
      await _notificationService.scheduleHabitNotifications(habit);
    }
    notifyListeners();
  }

  // Update existing habit - ASYNC for notifications
  Future<void> updateHabit(String id, Habit updatedHabit) async {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      await _saveHabits();
      // Reschedule notifications if enabled
      if (updatedHabit.enableNotifications) {
        await _notificationService.scheduleHabitNotifications(updatedHabit);
      } else {
        await _notificationService.cancelHabitNotifications(id);
      }
      notifyListeners();
    }
  }

  // Delete habit - ASYNC for notifications with error handling
  Future<void> deleteHabit(String id) async {
    try {
      // Try to cancel notifications, but don't fail if it doesn't work
      await _notificationService.cancelHabitNotifications(id);
    } catch (e) {
      print('Warning: Could not cancel notifications for habit $id: $e');
      // Continue with deletion even if notification cancellation fails
    }
    
    // Remove habit from list
    _habits.removeWhere((habit) => habit.id == id);
    await _saveHabits();
    notifyListeners();
  }

  // Toggle habit completion for today
  void toggleHabitCompletion(String habitId, {bool? completed, String? notes, int? value}) {
    final habit = getHabitById(habitId);
    if (habit == null) return;

    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    // Find existing progress for today
    final existingProgressIndex = habit.progress.indexWhere((p) {
      final progressDate = "${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}";
      return progressDate == todayString;
    });

    final newProgress = HabitProgress(
      id: "${habitId}_${today.millisecondsSinceEpoch}",
      date: today,
      completed: completed ?? !habit.isCompletedToday,
      notes: notes,
      value: value,
    );

    final updatedProgressList = List<HabitProgress>.from(habit.progress);
    
    if (existingProgressIndex != -1) {
      updatedProgressList[existingProgressIndex] = newProgress;
    } else {
      updatedProgressList.add(newProgress);
    }

    final updatedHabit = habit.copyWith(progress: updatedProgressList);
    // Use sync version to avoid breaking existing UI
    _updateHabitSync(habitId, updatedHabit);
  }

  // Private sync version for toggleHabitCompletion
  void _updateHabitSync(String id, Habit updatedHabit) {
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      _saveHabits();
      notifyListeners();
    }
  }

  // Add progress for a specific date - SAME AS BEFORE
  void addHabitProgress(String habitId, DateTime date, bool completed, {String? notes, int? value}) {
    final habit = getHabitById(habitId);
    if (habit == null) return;

    final progress = HabitProgress(
      id: "${habitId}_${date.millisecondsSinceEpoch}",
      date: date,
      completed: completed,
      notes: notes,
      value: value,
    );

    final updatedProgressList = List<HabitProgress>.from(habit.progress);
    updatedProgressList.add(progress);

    final updatedHabit = habit.copyWith(progress: updatedProgressList);
    _updateHabitSync(habitId, updatedHabit);
  }

  // Get completion statistics - SAME AS BEFORE
  Map<String, dynamic> getOverallStats() {
    if (activeHabits.isEmpty) {
      return {
        'totalHabits': 0,
        'completedToday': 0,
        'completionRate': 0.0,
        'longestStreak': 0,
      };
    }

    final totalHabits = todayHabits.length;
    final completedToday = completedTodayHabits.length;
    final completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;
    
    int longestStreak = 0;
    for (final habit in activeHabits) {
      final streak = habit.currentStreak;
      if (streak > longestStreak) longestStreak = streak;
    }

    return {
      'totalHabits': totalHabits,
      'completedToday': completedToday,
      'completionRate': completionRate,
      'longestStreak': longestStreak,
    };
  }

  // Get habits by category
  List<Habit> getHabitsByCategory(HabitCategory category) {
    return activeHabits.where((habit) => habit.category == category).toList();
  }

  // Load habits from storage
  void _loadHabits() async {
    _prefs = await SharedPreferences.getInstance();
    final habitsJson = _prefs.getString('habits');
    
    if (habitsJson != null) {
      try {
        final List<dynamic> habitsList = jsonDecode(habitsJson);
        _habits = habitsList.map((json) => Habit.fromJson(json)).toList();
        notifyListeners();
      } catch (e) {
        print('Error loading habits: $e');
        // If loading fails, start fresh
        _habits = [];
        _addSampleHabits();
      }
    } else {
      // Add some sample habits for development
      _addSampleHabits();
    }
  }

  // Save habits to storage - ASYNC version
  Future<void> _saveHabits() async {
    try {
      final habitsJson = jsonEncode(_habits.map((habit) => habit.toJson()).toList());
      await _prefs.setString('habits', habitsJson);
    } catch (e) {
      print('Error saving habits: $e');
    }
  }

  // NEW: Notification-related methods
  Future<bool> requestNotificationPermission() async {
    return await _notificationService.requestPermission();
  }

  Future<void> sendTestNotification() async {
    await _notificationService.sendImmediateNotification(
      title: 'Test Notification',
      body: 'Habit notifications are working!',
    );
  }

  // Add sample habits for development/demo
  void _addSampleHabits() {
    final now = DateTime.now();
    final sampleHabits = [
      Habit(
        id: 'sample_1',
        name: 'Drink Water',
        description: 'Drink 8 glasses of water daily',
        category: HabitCategory.health,
        color: Colors.blue,
        icon: Icons.local_drink,
        createdDate: now.subtract(Duration(days: 7)),
        targetValue: 8,
        unit: 'glasses',
      ),
      Habit(
        id: 'sample_2',
        name: 'Morning Exercise',
        description: '30 minutes of exercise every day',
        category: HabitCategory.fitness,
        color: Colors.orange,
        icon: Icons.fitness_center,
        createdDate: now.subtract(Duration(days: 5)),
        targetValue: 30,
        unit: 'minutes',
      ),
      Habit(
        id: 'sample_3',
        name: 'Read Books',
        description: 'Read for 20 minutes daily',
        category: HabitCategory.learning,
        color: Colors.green,
        icon: Icons.book,
        createdDate: now.subtract(Duration(days: 3)),
        targetValue: 20,
        unit: 'minutes',
      ),
      Habit(
        id: 'sample_4',
        name: 'Meditation',
        description: 'Daily mindfulness meditation',
        category: HabitCategory.mindfulness,
        color: Colors.purple,
        icon: Icons.self_improvement,
        createdDate: now.subtract(Duration(days: 2)),
        targetValue: 10,
        unit: 'minutes',
      ),
    ];

    for (final habit in sampleHabits) {
      _habits.add(habit);
    }
    _saveHabits();
    notifyListeners();
  }

  // Clear all habits - ASYNC version
  Future<void> clearAllHabits() async {
    await _notificationService.cancelAllNotifications();
    _habits.clear();
    await _saveHabits();
    notifyListeners();
  }

  // Export habits data
  String exportHabitsData() {
    return jsonEncode(_habits.map((habit) => habit.toJson()).toList());
  }

  // Import habits data
  void importHabitsData(String jsonData) {
    try {
      final List<dynamic> habitsList = jsonDecode(jsonData);
      _habits = habitsList.map((json) => Habit.fromJson(json)).toList();
      _saveHabits();
      notifyListeners();
    } catch (e) {
      throw Exception('Invalid habits data format');
    }
  }
}