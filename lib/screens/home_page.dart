// screens/home_page.dart
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
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTimeCard(context),
                  SizedBox(height: 24),
                  _buildStatsCard(context),
                  SizedBox(height: 24),
                  _buildTodayHabitsSection(context),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-habits'),
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Habits Tracker',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final now = _currentTime;
    
    final timeFormat = TimeOfDay.fromDateTime(now);
    final dateFormat = "${_getWeekdayName(now.weekday)}, ${_getMonthName(now.month)} ${now.day}";
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${timeFormat.hour.toString().padLeft(2, '0')}:${timeFormat.minute.toString().padLeft(2, '0')}",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final habitsProvider = context.watch<HabitsProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final stats = habitsProvider.getOverallStats();
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Completed',
                  '${stats['completedToday']}/${stats['totalHabits']}',
                  Icons.check_circle,
                  isDark ? AppColors.darkPrimary : AppColors.lightAccent,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Success Rate',
                  '${(stats['completionRate'] * 100).toInt()}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Streak',
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

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodayHabitsSection(BuildContext context) {
    final habitsProvider = context.watch<HabitsProvider>();
    final todayHabits = habitsProvider.todayHabits;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Habits',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/add-habits'),
              child: Text('See All'),
            ),
          ],
        ),
        SizedBox(height: 16),
        todayHabits.isEmpty
            ? _buildEmptyState(context)
            : Column(
                children: todayHabits.map((habit) => _buildHabitCard(context, habit)).toList(),
              ),
      ],
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit) {
    final habitsProvider = context.read<HabitsProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isCompleted = habit.isCompletedToday;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        isDark: isDark,
        child: ListTile(
          contentPadding: EdgeInsets.all(8),
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
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
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
                  SizedBox(width: 16),
                  if (habit.targetValue != null) ...[
                    Icon(Icons.flag, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('${habit.targetValue} ${habit.unit ?? ''}'),
                  ],
                ],
              ),
            ],
          ),
          trailing: GestureDetector(
            onTap: () => habitsProvider.toggleHabitCompletion(habit.id),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightAccent)
                    : Colors.transparent,
                border: Border.all(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.add,
                color: isCompleted 
                    ? (isDark ? AppColors.darkBackground : AppColors.lightText)
                    : (isDark ? AppColors.darkPrimary : AppColors.lightAccent),
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

  Widget _buildEmptyState(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
          ),
          SizedBox(height: 16),
          Text(
            'No habits for today',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            'Start building great habits by adding your first one!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}