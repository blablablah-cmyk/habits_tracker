import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habits_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';

class AddHabitsPage extends StatefulWidget {
  final String? habitId;

  const AddHabitsPage({Key? key, this.habitId}) : super(key: key);

  @override
  _AddHabitsPageState createState() => _AddHabitsPageState();
}

class _AddHabitsPageState extends State<AddHabitsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();

  HabitCategory _selectedCategory = HabitCategory.health;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  List<int> _selectedDays = [];
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.check_circle;
  
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _enableNotifications = false;
  List<int> _notificationOffsets = [15];
  
  bool get _isEditing => widget.habitId != null;
  
  final List<Color> _colorOptions = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.red, Colors.teal, Colors.pink, Colors.indigo,
    Colors.amber, Colors.cyan, Colors.deepOrange, Colors.deepPurple,
  ];

  final List<IconData> _iconOptions = [
    Icons.check_circle, Icons.fitness_center, Icons.book, Icons.local_drink,
    Icons.self_improvement, Icons.music_note, Icons.brush, Icons.work,
    Icons.school, Icons.favorite, Icons.home, Icons.restaurant,
    Icons.directions_run, Icons.bedtime, Icons.psychology, Icons.phone,
  ];

  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadHabitData();
    }
  }

  void _loadHabitData() {
    final habitsProvider = context.read<HabitsProvider>();
    final habit = habitsProvider.getHabitById(widget.habitId!);
    
    if (habit == null) {
      // Habit doesn't exist anymore (might have been deleted)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Habit no longer exists'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
      return;
    }
    
    // Load existing habit data
    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _targetValueController.text = habit.targetValue?.toString() ?? '';
    _unitController.text = habit.unit ?? '';
    _selectedCategory = habit.category;
    _selectedFrequency = habit.frequency;
    _selectedDays = List.from(habit.customDays);
    _selectedColor = habit.color;
    _selectedIcon = habit.icon;
    _startTime = habit.startTime;
    _endTime = habit.endTime;
    _enableNotifications = habit.enableNotifications;
    _notificationOffsets = List.from(habit.notificationOffsets);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    // Safety check: if editing and habit no longer exists, show error screen
    if (_isEditing) {
      final habitsProvider = context.watch<HabitsProvider>();
      final habit = habitsProvider.getHabitById(widget.habitId!);
      
      if (habit == null) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Habit Not Found'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Habit Not Found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  'This habit may have been deleted.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'Add New Habit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBasicInfo(isDark),
              SizedBox(height: 20),
              _buildCategory(isDark),
              SizedBox(height: 20),
              _buildFrequency(isDark),
              if (_selectedFrequency == HabitFrequency.timed) ...[
                SizedBox(height: 20),
                _buildTimeSchedule(isDark),
              ],
              SizedBox(height: 20),
              _buildNotifications(isDark),
              SizedBox(height: 20),
              _buildCustomization(isDark),
              SizedBox(height: 20),
              _buildTarget(isDark),
              SizedBox(height: 40),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Habit Name *',
              hintText: 'e.g., Morning Exercise',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(_selectedIcon, color: _selectedColor),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a habit name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Brief description of your habit',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HabitCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(_getCategoryName(category)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
                selectedColor: (isDark ? AppColors.darkPrimary : AppColors.lightAccent).withOpacity(0.3),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequency(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...HabitFrequency.values.map((frequency) {
            return RadioListTile<HabitFrequency>(
              title: Text(_getFrequencyName(frequency)),
              subtitle: Text(_getFrequencyDescription(frequency)),
              value: frequency,
              groupValue: _selectedFrequency,
              onChanged: (value) => setState(() {
                _selectedFrequency = value!;
                if (value != HabitFrequency.custom && value != HabitFrequency.timed) {
                  _selectedDays.clear();
                }
                if (value != HabitFrequency.timed) {
                  _startTime = null;
                  _endTime = null;
                }
              }),
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
          if (_selectedFrequency == HabitFrequency.custom) ...[
            SizedBox(height: 16),
            Text('Select Days:', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return FilterChip(
                  label: Text(_weekdays[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(index);
                      } else {
                        _selectedDays.remove(index);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSchedule(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          // Start Time
          Card(
            child: ListTile(
              leading: Icon(Icons.access_time, color: _selectedColor),
              title: Text('Start Time *'),
              subtitle: Text(_startTime != null 
                  ? _formatTime(_startTime!)
                  : 'Tap to set start time'),
              trailing: Icon(Icons.edit),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? TimeOfDay.now(),
                  helpText: 'Select Start Time',
                );
                if (time != null) {
                  setState(() => _startTime = time);
                }
              },
            ),
          ),
          
          SizedBox(height: 8),
          
          // End Time
          Card(
            child: ListTile(
              leading: Icon(Icons.access_time_filled, color: _selectedColor.withOpacity(0.7)),
              title: Text('End Time (Optional)'),
              subtitle: Text(_endTime != null 
                  ? _formatTime(_endTime!)
                  : 'Tap to set end time'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endTime != null)
                    IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _endTime = null),
                    ),
                  Icon(Icons.edit),
                ],
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime ?? _startTime?.replacing(hour: (_startTime!.hour + 1) % 24) ?? TimeOfDay.now(),
                  helpText: 'Select End Time',
                );
                if (time != null) {
                  setState(() => _endTime = time);
                }
              },
            ),
          ),
          
          SizedBox(height: 16),
          Text('Days (Optional):', style: TextStyle(fontWeight: FontWeight.w600)),
          Text('Leave empty for daily, or select specific days', 
               style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return FilterChip(
                label: Text(_weekdays[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(index);
                    } else {
                      _selectedDays.remove(index);
                    }
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SwitchListTile(
            title: Text('Enable Reminders'),
            subtitle: Text('Get notified about this habit'),
            value: _enableNotifications,
            onChanged: (value) => setState(() => _enableNotifications = value),
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableNotifications && _selectedFrequency == HabitFrequency.timed) ...[
            SizedBox(height: 16),
            Text('Reminder Times:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Minutes before start time:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 30, 60].map((minutes) {
                final isSelected = _notificationOffsets.contains(minutes);
                return FilterChip(
                  label: Text('${minutes}min'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _notificationOffsets.add(minutes);
                      } else {
                        _notificationOffsets.remove(minutes);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ] else if (_enableNotifications) ...[
            SizedBox(height: 8),
            Text(
              'Daily reminder at 9:00 AM',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomization(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 16),
          Text('Icon:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _iconOptions.map((icon) {
              final isSelected = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: isSelected ? _selectedColor : Colors.grey),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTarget(bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target (Optional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Set a measurable goal for your habit', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _targetValueController,
                  decoration: InputDecoration(
                    labelText: 'Target',
                    hintText: '8',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    hintText: 'glasses, minutes, pages',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveHabit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _isEditing ? 'Update Habit' : 'Create Habit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }

  void _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation
    if (_selectedFrequency == HabitFrequency.custom && _selectedDays.isEmpty) {
      _showError('Please select at least one day for custom frequency');
      return;
    }
    
    if (_selectedFrequency == HabitFrequency.timed && _startTime == null) {
      _showError('Please set a start time for scheduled habits');
      return;
    }

    try {
      final habitsProvider = context.read<HabitsProvider>();
      
      // Request notification permission if needed
      if (_enableNotifications) {
        final granted = await habitsProvider.requestNotificationPermission();
        if (!granted) {
          _showError('Notification permission is required for reminders');
          return;
        }
      }
      
      final habit = Habit(
        id: _isEditing ? widget.habitId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        customDays: _selectedDays,
        color: _selectedColor,
        icon: _selectedIcon,
        createdDate: _isEditing 
            ? habitsProvider.getHabitById(widget.habitId!)!.createdDate
            : DateTime.now(),
        targetValue: _targetValueController.text.isEmpty ? null : int.tryParse(_targetValueController.text),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        progress: _isEditing ? habitsProvider.getHabitById(widget.habitId!)!.progress : [],
        startTime: _startTime,
        endTime: _endTime,
        enableNotifications: _enableNotifications,
        notificationOffsets: _notificationOffsets.isEmpty ? [15] : _notificationOffsets,
      );

      if (_isEditing) {
        await habitsProvider.updateHabit(widget.habitId!, habit);
        _showSuccess('Habit updated successfully!');
      } else {
        await habitsProvider.addHabit(habit);
        _showSuccess('Habit created successfully!');
      }

      Navigator.pop(context);
    } catch (e) {
      _showError('Error saving habit: $e');
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Habit'),
        content: Text('Are you sure you want to delete this habit?\n\nThis will permanently remove all progress data and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: _deleteHabit,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteHabit() async {
    try {
      final habitsProvider = context.read<HabitsProvider>();
      await habitsProvider.deleteHabit(widget.habitId!);
      
      // Close the confirmation dialog
      if (mounted) Navigator.pop(context);
      
      // Close the edit screen and return to previous screen
      if (mounted) Navigator.pop(context);
      
      // Show success message if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Habit deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close the confirmation dialog
      if (mounted) Navigator.pop(context);
      
      // Show error but stay on current screen
      if (mounted) _showError('Failed to delete habit: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getCategoryName(HabitCategory category) {
    switch (category) {
      case HabitCategory.health: return 'Health';
      case HabitCategory.fitness: return 'Fitness';
      case HabitCategory.productivity: return 'Productivity';
      case HabitCategory.mindfulness: return 'Mindfulness';
      case HabitCategory.learning: return 'Learning';
      case HabitCategory.social: return 'Social';
      case HabitCategory.creative: return 'Creative';
      case HabitCategory.other: return 'Other';
    }
  }

  String _getFrequencyName(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily: return 'Daily';
      case HabitFrequency.weekly: return 'Weekly';
      case HabitFrequency.custom: return 'Custom Days';
      case HabitFrequency.timed: return 'Scheduled Time';
    }
  }

  String _getFrequencyDescription(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily: return 'Every day';
      case HabitFrequency.weekly: return 'Once a week (Monday)';
      case HabitFrequency.custom: return 'Choose specific days';
      case HabitFrequency.timed: return 'Set specific time slots (e.g., 10:00-11:00)';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}