import 'package:flutter/material.dart';

enum HabitFrequency {
  daily,
  weekly,
  custom,
  timed, // New: Time-based habits
}

enum HabitCategory {
  health,
  fitness,
  productivity,
  mindfulness,
  learning,
  social,
  creative,
  other,
}

class HabitProgress {
  final String id;
  final DateTime date;
  final bool completed;
  final String? notes;
  final int? value; // For quantifiable habits

  HabitProgress({
    required this.id,
    required this.date,
    required this.completed,
    this.notes,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'completed': completed,
      'notes': notes,
      'value': value,
    };
  }

  factory HabitProgress.fromJson(Map<String, dynamic> json) {
    return HabitProgress(
      id: json['id'],
      date: DateTime.parse(json['date']),
      completed: json['completed'],
      notes: json['notes'],
      value: json['value'],
    );
  }
}

class Habit {
  final String id;
  final String name;
  final String? description;
  final HabitCategory category;
  final HabitFrequency frequency;
  final List<int> customDays; // For custom frequency (0=Monday, 6=Sunday)
  final TimeOfDay? startTime; // New: Start time for timed habits
  final TimeOfDay? endTime;   // New: End time for timed habits
  final bool enableNotifications; // New: Enable/disable notifications for this habit
  final List<int> notificationOffsets; // New: Minutes before start time to notify (e.g., [5, 15] for 5min and 15min before)
  final Color color;
  final IconData icon;
  final DateTime createdDate;
  final int? targetValue; // For quantifiable habits (e.g., 8 glasses of water)
  final String? unit; // e.g., "glasses", "minutes", "pages"
  final List<HabitProgress> progress;
  final bool isActive;

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.frequency = HabitFrequency.daily,
    this.customDays = const [],
    this.startTime,
    this.endTime,
    this.enableNotifications = false,
    this.notificationOffsets = const [15], // Default: 15 minutes before
    this.color = Colors.blue,
    this.icon = Icons.check_circle,
    required this.createdDate,
    this.targetValue,
    this.unit,
    this.progress = const [],
    this.isActive = true,
  });

  // Calculate streak
  int get currentStreak {
    if (progress.isEmpty) return 0;
    
    final sortedProgress = List<HabitProgress>.from(progress)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (var p in sortedProgress) {
      final progressDate = DateTime(p.date.year, p.date.month, p.date.day);
      final currentCheck = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      if (progressDate == currentCheck && p.completed) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else if (progressDate.isBefore(currentCheck)) {
        break;
      }
    }
    
    return streak;
  }

  // Calculate completion percentage for current week/month
  double getCompletionRate({int days = 7}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    
    final recentProgress = progress.where((p) => 
      p.date.isAfter(startDate.subtract(Duration(days: 1))) && 
      p.date.isBefore(now.add(Duration(days: 1)))
    ).toList();
    
    if (recentProgress.isEmpty) return 0.0;
    
    final completedDays = recentProgress.where((p) => p.completed).length;
    return completedDays / days;
  }

  // Check if habit should be done today
  bool shouldBeDoneToday() {
    if (!isActive) return false;
    
    final today = DateTime.now().weekday - 1; // Convert to 0-6 range
    
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return today == 0; // Monday
      case HabitFrequency.custom:
        return customDays.contains(today);
      case HabitFrequency.timed:
        return customDays.isEmpty ? true : customDays.contains(today); // If no custom days, daily
    }
  }

  // Check if habit is currently in its time window
  bool get isInTimeWindow {
    if (frequency != HabitFrequency.timed || startTime == null) return true;
    
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime != null ? (endTime!.hour * 60 + endTime!.minute) : (startMinutes + 60);
    
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  // Get time range string for display
  String? get timeRangeString {
    if (frequency != HabitFrequency.timed || startTime == null) return null;
    
    final startStr = "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
    if (endTime != null) {
      final endStr = "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";
      return "$startStr - $endStr";
    }
    return startStr;
  }

  // Check if habit is completed today
  bool get isCompletedToday {
    final today = DateTime.now();
    final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    return progress.any((p) {
      final progressDate = "${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}";
      return progressDate == todayString && p.completed;
    });
  }

  Habit copyWith({
    String? name,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    List<int>? customDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? enableNotifications,
    List<int>? notificationOffsets,
    Color? color,
    IconData? icon,
    int? targetValue,
    String? unit,
    List<HabitProgress>? progress,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationOffsets: notificationOffsets ?? this.notificationOffsets,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdDate: createdDate,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.index,
      'frequency': frequency.index,
      'customDays': customDays,
      'startTime': startTime != null ? {'hour': startTime!.hour, 'minute': startTime!.minute} : null,
      'endTime': endTime != null ? {'hour': endTime!.hour, 'minute': endTime!.minute} : null,
      'enableNotifications': enableNotifications,
      'notificationOffsets': notificationOffsets,
      'color': color.value,
      'icon': icon.codePoint,
      'createdDate': createdDate.toIso8601String(),
      'targetValue': targetValue,
      'unit': unit,
      'progress': progress.map((p) => p.toJson()).toList(),
      'isActive': isActive,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: HabitCategory.values[json['category']],
      frequency: HabitFrequency.values[json['frequency']],
      customDays: List<int>.from(json['customDays'] ?? []),
      startTime: json['startTime'] != null 
          ? TimeOfDay(hour: json['startTime']['hour'], minute: json['startTime']['minute'])
          : null,
      endTime: json['endTime'] != null 
          ? TimeOfDay(hour: json['endTime']['hour'], minute: json['endTime']['minute'])
          : null,
      enableNotifications: json['enableNotifications'] ?? false,
      notificationOffsets: List<int>.from(json['notificationOffsets'] ?? [15]),
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      createdDate: DateTime.parse(json['createdDate']),
      targetValue: json['targetValue'],
      unit: json['unit'],
      progress: (json['progress'] as List?)
          ?.map((p) => HabitProgress.fromJson(p))
          .toList() ?? [],
      isActive: json['isActive'] ?? true,
    );
  }
}

// Helper class for habit statistics
class HabitStats {
  final Habit habit;

  HabitStats(this.habit);

  int get totalCompletions => habit.progress.where((p) => p.completed).length;
  
  int get totalDays => habit.progress.length;
  
  double get overallCompletionRate => 
    totalDays > 0 ? totalCompletions / totalDays : 0.0;
  
  int get longestStreak {
    if (habit.progress.isEmpty) return 0;
    
    final sortedProgress = List<HabitProgress>.from(habit.progress)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (var p in sortedProgress) {
      if (p.completed) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return maxStreak;
  }
  
  Map<String, int> get weeklyCompletions {
    final Map<String, int> weekly = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      final completed = habit.progress.any((p) {
        final progressDate = "${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}";
        return progressDate == dateKey && p.completed;
      });
      
      weekly[dateKey] = completed ? 1 : 0;
    }
    
    return weekly;
  }
}