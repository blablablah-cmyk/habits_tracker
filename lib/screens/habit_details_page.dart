// screens/habit_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habits_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';
import 'add_habits_page.dart';

class HabitDetailsPage extends StatefulWidget {
  @override
  _HabitDetailsPageState createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  String? habitId;
  int _selectedViewIndex = 0; // 0: Week, 1: Month, 2: Statistics

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    habitId = ModalRoute.of(context)!.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    if (habitId == null) {
      return Scaffold(
        body: Center(child: Text('Habit not found')),
      );
    }

    final habitsProvider = context.watch<HabitsProvider>();
    final habit = habitsProvider.getHabitById(habitId!);

    if (habit == null) {
      return Scaffold(
        body: Center(child: Text('Habit not found')),
      );
    }

    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, habit, isDark),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHabitOverview(context, habit, isDark),
                SizedBox(height: 24),
                _buildViewSelector(context, isDark),
                SizedBox(height: 16),
                _buildSelectedView(context, habit, isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Habit habit, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      backgroundColor: habit.color.withOpacity(0.1),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          habit.name,
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                habit.color.withOpacity(0.3),
                habit.color.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              habit.icon,
              size: 80,
              color: habit.color,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitsPage(habitId: habit.id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitOverview(BuildContext context, Habit habit, bool isDark) {
    final stats = HabitStats(habit);
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habit.description != null) ...[
            Text(
              habit.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Current Streak',
                  '${habit.currentStreak}',
                  'days',
                  Icons.local_fire_department,
                  Colors.orange,
                  isDark,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Best Streak',
                  '${stats.longestStreak}',
                  'days',
                  Icons.emoji_events,
                  Colors.amber,
                  isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Completion Rate',
                  '${(stats.overallCompletionRate * 100).toInt()}',
                  '%',
                  Icons.trending_up,
                  Colors.green,
                  isDark,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Days',
                  '${stats.totalCompletions}',
                  '/${stats.totalDays}',
                  Icons.calendar_today,
                  Colors.blue,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(BuildContext context, bool isDark) {
    final tabs = ['Week View', 'Month View', 'Statistics'];
    
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedViewIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedViewIndex = index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkPrimary : AppColors.lightAccent)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? AppColors.darkBackground : AppColors.lightText)
                        : (isDark ? AppColors.darkText : AppColors.lightText),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedView(BuildContext context, Habit habit, bool isDark) {
    switch (_selectedViewIndex) {
      case 0:
        return _buildWeekView(context, habit, isDark);
      case 1:
        return _buildMonthView(context, habit, isDark);
      case 2:
        return _buildStatisticsView(context, habit, isDark);
      default:
        return Container();
    }
  }

  Widget _buildWeekView(BuildContext context, Habit habit, bool isDark) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));
              final isCompleted = habit.progress.any((p) {
                final pDate = DateTime(p.date.year, p.date.month, p.date.day);
                final checkDate = DateTime(date.year, date.month, date.day);
                return pDate == checkDate && p.completed;
              });
              
              final isToday = DateTime(date.year, date.month, date.day) == 
                              DateTime(now.year, now.month, now.day);
              
              return Column(
                children: [
                  Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? habit.color
                          : (isToday 
                              ? habit.color.withOpacity(0.3)
                              : Colors.transparent),
                      border: Border.all(
                        color: isToday 
                            ? habit.color 
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        width: isToday ? 2 : 1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.white
                              : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: habit.color,
                      size: 16,
                    )
                  else
                    SizedBox(height: 16),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(BuildContext context, Habit habit, bool isDark) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = monthEnd.day;
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final date = monthStart.add(Duration(days: index));
              final isCompleted = habit.progress.any((p) {
                final pDate = DateTime(p.date.year, p.date.month, p.date.day);
                final checkDate = DateTime(date.year, date.month, date.day);
                return pDate == checkDate && p.completed;
              });
              
              final isToday = DateTime(date.year, date.month, date.day) == 
                              DateTime(now.year, now.month, now.day);
              
              return Container(
                decoration: BoxDecoration(
                  color: isCompleted
                      ? habit.color.withOpacity(0.8)
                      : (isToday 
                          ? habit.color.withOpacity(0.3)
                          : Colors.transparent),
                  border: Border.all(
                    color: isToday 
                        ? habit.color 
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.white
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView(BuildContext context, Habit habit, bool isDark) {
    final stats = HabitStats(habit);
    
    return Column(
      children: [
        GlassContainer(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Over Time',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildProgressChart(context, habit, isDark),
            ],
          ),
        ),
        SizedBox(height: 16),
        GlassContainer(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildRecentActivity(context, habit, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(BuildContext context, Habit habit, bool isDark) {
    // Simple bar chart showing last 7 days
    final now = DateTime.now();
    final weekData = <String, bool>{};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.month}/${date.day}";
      final isCompleted = habit.progress.any((p) {
        final pDate = DateTime(p.date.year, p.date.month, p.date.day);
        final checkDate = DateTime(date.year, date.month, date.day);
        return pDate == checkDate && p.completed;
      });
      weekData[dateKey] = isCompleted;
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: weekData.entries.map((entry) {
            return Column(
              children: [
                Container(
                  width: 24,
                  height: entry.value ? 60 : 20,
                  decoration: BoxDecoration(
                    color: entry.value 
                        ? habit.color 
                        : habit.color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, Habit habit, bool isDark) {
    final recentProgress = List<HabitProgress>.from(habit.progress)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final displayProgress = recentProgress.take(5).toList();
    
    if (displayProgress.isEmpty) {
      return Center(
        child: Text(
          'No activity yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    
    return Column(
      children: displayProgress.map((progress) {
        final date = progress.date;
        final dateStr = "${date.month}/${date.day}/${date.year}";
        
        return ListTile(
          leading: Icon(
            progress.completed ? Icons.check_circle : Icons.cancel,
            color: progress.completed ? Colors.green : Colors.red,
          ),
          title: Text(dateStr),
          subtitle: progress.notes != null ? Text(progress.notes!) : null,
          trailing: progress.value != null 
              ? Text('${progress.value} ${habit.unit ?? ''}')
              : null,
        );
      }).toList(),
    );
  }
}