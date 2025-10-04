import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/habits_provider.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSection(context, isDark),
          const SizedBox(height: 24),
          _buildNotificationSection(context, isDark),
          const SizedBox(height: 24),
          _buildDataSection(context, isDark),
          const SizedBox(height: 24),
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

  Widget _buildNotificationSection(BuildContext context, bool isDark) {
    final habitsProvider = context.read<HabitsProvider>();
    
    return GlassContainer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: isDark ? AppColors.darkPrimary : AppColors.lightAccent,
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Test Notifications'),
            subtitle: const Text('Send a test notification to check if they work'),
            trailing: const Icon(Icons.send),
            onTap: () async {
              await habitsProvider.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent! -- only on mobile devices')),
                );
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Notifications'),
            subtitle: const Text('How habit reminders work'),
            onTap: () => _showNotificationInfo(context),
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
            leading: Icon(Icons.backup, color: Colors.green),
            title: Text('Export Data'),
            subtitle: Text('Save your habits data as a backup'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _exportData(context, habitsProvider),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.restore, color: Colors.blue),
            title: Text('Import Data'),
            subtitle: Text('Restore habits from a backup file'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _importData(context, habitsProvider),
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
            subtitle: Text('1.0.1'),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.school),
            title: Text('University Project'),
            subtitle: Text('Built with Flutter for habit tracking'),
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

  // FIXED EXPORT FUNCTION
  Future<void> _exportData(BuildContext context, HabitsProvider habitsProvider) async {
    try {
      final data = habitsProvider.exportHabitsData();
      
      // Let user choose where to save the file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Habits Data',
        fileName: 'habits_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (outputPath != null) {
        // Write data to file
        final file = File(outputPath);
        await file.writeAsString(data);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Data exported successfully!\n${outputPath.split(Platform.pathSeparator).last}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // User cancelled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export cancelled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // FIXED IMPORT FUNCTION
  Future<void> _importData(BuildContext context, HabitsProvider habitsProvider) async {
    try {
      // Let user pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Habits Backup File',
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Read file content
        final data = await file.readAsString();
        
        // Validate JSON (basic check)
        if (data.trim().isEmpty || !data.trim().startsWith('[')) {
          throw Exception('Invalid backup file format');
        }
        
        // Show confirmation dialog
        if (context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Import Data'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This will replace all your current habits with the imported data.'),
                    SizedBox(height: 16),
                    Text(
                      'File: ${result.files.single.name}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Size: ${(data.length / 1024).toStringAsFixed(2)} KB',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This action cannot be undone!',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text('Import'),
                  ),
                ],
              );
            },
          );
          
          if (confirmed == true) {
            // Import the data
            habitsProvider.importHabitsData(data);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Data imported successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } else {
        // User cancelled file selection
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import cancelled'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context, HabitsProvider habitsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear All Data'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• All your habits'),
              Text('• All progress data'),
              Text('• All statistics'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await habitsProvider.clearAllHabits();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All data has been cleared'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Clear All Data'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How Notifications Work'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Types:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Timed Habits: Get reminders before your scheduled time'),
                Text('• Regular Habits: Daily reminder at 9:00 AM'),
                SizedBox(height: 16),
                Text(
                  'Scheduling:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Notifications are set when you create/update habits'),
                Text('• They repeat automatically based on your habit frequency'),
                Text('• Completed habits won\'t send reminders that day'),
                SizedBox(height: 16),
                Text(
                  'Customization:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• You can enable/disable notifications per habit'),
                Text('• Set multiple reminder times for timed habits'),
                Text('• Notifications respect your system settings'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notifications are only available on mobile devices',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  'Backup & Restore:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Export your data regularly for backup'),
                Text('• Import to restore or transfer to another device'),
                Text('• JSON files are stored in your chosen location'),
                SizedBox(height: 16),
                Text(
                  'Themes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Auto: Switches between light (day) and dark (night)'),
                Text('• Light: Always uses light theme with silver accents'),
                Text('• Dark: Always uses dark theme with gold accents'),
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