// screens/add_habits_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habits_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';

class AddHabitsPage extends StatefulWidget {
  final String? habitId; // For editing existing habit

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
    
    if (habit != null) {
      _nameController.text = habit.name;
      _descriptionController.text = habit.description ?? '';
      _targetValueController.text = habit.targetValue?.toString() ?? '';
      _unitController.text = habit.unit ?? '';
      _selectedCategory = habit.category;
      _selectedFrequency = habit.frequency;
      _selectedDays = List.from(habit.customDays);
      _selectedColor = habit.color;
      _selectedIcon = habit.icon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'Add New Habit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(context, isDark),
            SizedBox(height: 24),
            _buildCategorySection(context, isDark),
            SizedBox(height: 24),
            _buildFrequencySection(context, isDark),
            SizedBox(height: 24),
            _buildCustomizationSection(context, isDark),
            SizedBox(height: 24),
            _buildTargetSection(context, isDark),
            SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Habit Name',
              hintText: 'e.g., Drink Water, Exercise',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(_selectedIcon, color: _selectedColor),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
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
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HabitCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimary : AppColors.lightAccent)
                        : Colors.transparent,
                    border: Border.all(
                      color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getCategoryName(category),
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? AppColors.darkBackground : AppColors.lightText)
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Column(
            children: HabitFrequency.values.map((frequency) {
              return RadioListTile<HabitFrequency>(
                title: Text(_getFrequencyName(frequency)),
                subtitle: Text(_getFrequencyDescription(frequency)),
                value: frequency,
                groupValue: _selectedFrequency,
                onChanged: (value) => setState(() {
                  _selectedFrequency = value!;
                  if (value != HabitFrequency.custom) {
                    _selectedDays.clear();
                  }
                }),
              );
            }).toList(),
          ),
          if (_selectedFrequency == HabitFrequency.custom) ...[
            SizedBox(height: 16),
            Text('Select Days:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                    }
                  }),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.darkPrimary : AppColors.lightAccent)
                          : Colors.transparent,
                      border: Border.all(
                        color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _weekdays[index],
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? AppColors.darkBackground : AppColors.lightText)
                              : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomizationSection(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
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
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          Text('Icon', style: Theme.of(context).textTheme.titleMedium),
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
                    color: isSelected
                        ? _selectedColor.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _selectedColor : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? _selectedColor : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target (Optional)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Set a measurable target for your habit',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _targetValueController,
                  decoration: InputDecoration(
                    labelText: 'Target Value',
                    hintText: '8',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveHabit,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _isEditing ? 'Update Habit' : 'Create Habit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedFrequency == HabitFrequency.custom && _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one day for custom frequency')),
        );
        return;
      }

      final habitsProvider = context.read<HabitsProvider>();
      
      final habit = Habit(
        id: _isEditing ? widget.habitId! : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        frequency: _selectedFrequency,
        customDays: _selectedDays,
        color: _selectedColor,
        icon: _selectedIcon,
        createdDate: _isEditing 
            ? habitsProvider.getHabitById(widget.habitId!)!.createdDate
            : DateTime.now(),
        targetValue: _targetValueController.text.isEmpty 
            ? null 
            : int.tryParse(_targetValueController.text),
        unit: _unitController.text.trim().isEmpty 
            ? null 
            : _unitController.text.trim(),
        progress: _isEditing 
            ? habitsProvider.getHabitById(widget.habitId!)!.progress
            : [],
      );

      if (_isEditing) {
        habitsProvider.updateHabit(widget.habitId!, habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit updated successfully!')),
        );
      } else {
        habitsProvider.addHabit(habit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit created successfully!')),
        );
      }

      Navigator.pop(context);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Habit'),
          content: Text('Are you sure you want to delete this habit? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final habitsProvider = context.read<HabitsProvider>();
                habitsProvider.deleteHabit(widget.habitId!);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close edit page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Habit deleted successfully')),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryName(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.creative:
        return 'Creative';
      case HabitCategory.other:
        return 'Other';
    }
  }

  String _getFrequencyName(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  String _getFrequencyDescription(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekly:
        return 'Once a week (Monday)';
      case HabitFrequency.custom:
        return 'Choose specific days';
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