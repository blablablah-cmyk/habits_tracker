import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/habits_provider.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildThemeSection(context, isDark),
          SizedBox(height: 24),
          _buildDataSection(context, isDark),
          SizedBox(height: 24),
          _buildAboutSection(context, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, bool isDark) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
              ),
              SizedBox(width: 12),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Column(
            children: ThemePreference.values.map((preference) {
              return RadioListTile<ThemePreference>(
                title: Text(_getThemePreferenceName(preference)),
                subtitle: Text(_getThemePreferenceDescription(preference, themeProvider)),
                value: preference,
                groupValue: themeProvider.themePreference,
                onChanged: (value) => themeProvider.setThemePreference(value!),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
            ),
            title: Text('Current Theme'),
            subtitle: Text(themeProvider.getThemeDescription()),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, bool isDark) {
    final habitsProvider = context.read<HabitsProvider>();
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
              ),
              SizedBox(width: 12),
              Text(
                'Data Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text('Export Data'),
            subtitle: Text('Save your habits data as a backup'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showExportDialog(context, habitsProvider),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.restore),
            title: Text('Import Data'),
            subtitle: Text('Restore habits from a backup file'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showImportDialog(context, habitsProvider),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: Text('Delete all habits and progress'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showClearDataDialog(context, habitsProvider),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
              ),
              SizedBox(width: 12),
              Text(
                'About',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.apps),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.school),
            title: Text('University Project'),
            subtitle: Text('Built with Flutter for habit tracking'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Design Style'),
            subtitle: Text('Art Deco with Glassmorphism'),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('How to Use'),
            subtitle: Text('Learn how to get the most out of this app'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showHelpDialog(context),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, HabitsProvider habitsProvider) {
    final data = habitsProvider.exportHabitsData();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your habits data has been prepared for export.'),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Data ready for export\n(${data.length} characters)',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // In a real app, you would save the file or share it
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export feature would save the file here')),
                );
                Navigator.pop(context);
              },
              child: Text('Export'),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, HabitsProvider habitsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Import Data'),
          content: Text(
            'This feature would allow you to select and import a backup file. '
            'All current data would be replaced.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // In a real app, you would open a file picker
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import feature would open file picker here')),
                );
                Navigator.pop(context);
              },
              child: Text('Select File'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog(BuildContext context, HabitsProvider habitsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Data'),
          content: Text(
            'This will permanently delete all your habits and progress data. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                habitsProvider.clearAllHabits();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All data has been cleared')),
                );
              },
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How to Use'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Getting Started:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. Tap the + button to add your first habit'),
                Text('2. Choose a name, category, and frequency'),
                Text('3. Customize the color and icon'),
                Text('4. Set optional targets for measurable habits'),
                SizedBox(height: 16),
                Text(
                  'Daily Use:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. Check off completed habits on the home page'),
                Text('2. View your progress and streaks'),
                Text('3. Tap on any habit to see detailed statistics'),
                SizedBox(height: 16),
                Text(
                  'Themes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Auto: Switches between light (day) and dark (night) themes'),
                Text('• Light: Always uses light theme'),
                Text('• Dark: Always uses dark theme'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  String _getThemePreferenceName(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.system:
        return 'Auto (Day/Night)';
      case ThemePreference.light:
        return 'Light Theme';
      case ThemePreference.dark:
        return 'Dark Theme';
    }
  }

  String _getThemePreferenceDescription(ThemePreference preference, ThemeProvider provider) {
    switch (preference) {
      case ThemePreference.system:
        return 'Automatically switches based on time of day';
      case ThemePreference.light:
        return 'Always use light theme with silver accents';
      case ThemePreference.dark:
        return 'Always use dark theme with gold accents';
    }
  }
}