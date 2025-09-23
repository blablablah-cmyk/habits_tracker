import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/habits_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update time every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              _buildHeader(context),
              SizedBox(height: 24),
              
              // Current Time Card
              _buildTimeCard(context),
              SizedBox(height: 24),
              
              // Stats Overview
              _buildStatsOverview(context),
              SizedBox(height: 24),
              
              // Today's Habits
              _buildTodaysHabits(context),
              SizedBox(height: 24),
              
              // Timed Habits (if any exist)
              _buildTimedHabits(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-habits'),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // ignore: unused_local_variable
    final themeProvider = context.watch<ThemeProvider>();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Habits Tracker',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    
    final now = _currentTime;
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateString = "${_getWeekdayName(now.weekday)}, ${_getMonthName(now.month)} ${now.day}";
    
    return GlassContainer(
      isDark: isDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateString,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                timeString,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getGreeting(now.hour),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context) {
    final habitsProvider = context.watch<HabitsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    
    final stats = habitsProvider.getOverallStats();
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  '${stats['completedToday']}/${stats['totalHabits']}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '${(stats['completionRate'] * 100).toInt()}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Best Streak',
                  '${stats['longestStreak']}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodaysHabits(BuildContext context) {
    final habitsProvider = context.watch<HabitsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    
    final todayHabits = habitsProvider.todayHabits;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Habits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/add-habits'),
              child: Text('Add More'),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (todayHabits.isEmpty)
          _buildEmptyHabitsState(context, isDark)
        else
          ...todayHabits.map((habit) => _buildHabitItem(context, habit, isDark)),
      ],
    );
  }

  Widget _buildEmptyHabitsState(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No habits for today',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Start building great habits!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-habits'),
            child: Text('Add Your First Habit'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(BuildContext context, Habit habit, bool isDark) {
    final habitsProvider = context.read<HabitsProvider>();
    final isCompleted = habit.isCompletedToday;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        isDark: isDark,
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: habit.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              habit.icon,
              color: habit.color,
              size: 24,
            ),
          ),
          title: Text(
            habit.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (habit.description != null) ...[
                Text(habit.description!),
                SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                  SizedBox(width: 4),
                  Text('${habit.currentStreak} day streak'),
                  if (habit.targetValue != null) ...[
                    SizedBox(width: 16),
                    Icon(Icons.flag, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('${habit.targetValue} ${habit.unit ?? ''}'),
                  ],
                ],
              ),
              // Show time info for timed habits
              if (habit.frequency == HabitFrequency.timed && habit.timeRangeString != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: habit.color),
                    SizedBox(width: 4),
                    Text(
                      habit.timeRangeString!,
                      style: TextStyle(
                        color: habit.isInTimeWindow ? habit.color : Colors.grey,
                        fontWeight: habit.isInTimeWindow ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (habit.isInTimeWindow) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: habit.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: habit.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          trailing: GestureDetector(
            onTap: () => habitsProvider.toggleHabitCompletion(habit.id),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.add,
                color: isCompleted ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
          ),
          onTap: () => Navigator.pushNamed(
            context,
            '/habit-details',
            arguments: habit.id,
          ),
        ),
      ),
    );
  }

  Widget _buildTimedHabits(BuildContext context) {
    final habitsProvider = context.watch<HabitsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    
    final timedHabits = habitsProvider.timedHabits;
    
    // Don't show section if no timed habits
    if (timedHabits.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Scheduled Habits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...timedHabits.map((habit) => _buildTimedHabitItem(context, habit, isDark)),
      ],
    );
  }

  Widget _buildTimedHabitItem(BuildContext context, Habit habit, bool isDark) {
    final habitsProvider = context.read<HabitsProvider>();
    final isCompleted = habit.isCompletedToday;
    final isActive = habit.isInTimeWindow;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        isDark: isDark,
        child: ListTile(
          leading: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: habit.color.withOpacity(isActive ? 0.4 : 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: isActive ? Border.all(color: habit.color, width: 2) : null,
                ),
                child: Icon(
                  habit.icon,
                  color: habit.color,
                  size: 24,
                ),
              ),
              if (isActive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: habit.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            habit.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: habit.color),
                  SizedBox(width: 4),
                  Text(
                    habit.timeRangeString ?? '',
                    style: TextStyle(
                      color: isActive ? habit.color : null,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isActive) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: habit.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (habit.enableNotifications) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.notifications, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Reminders enabled',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: GestureDetector(
            onTap: () => habitsProvider.toggleHabitCompletion(habit.id),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.add,
                color: isCompleted ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
          ),
          onTap: () => Navigator.pushNamed(
            context,
            '/habit-details',
            arguments: habit.id,
          ),
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}