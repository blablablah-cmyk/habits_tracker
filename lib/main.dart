import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/habits_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_page.dart';
import 'screens/add_habits_page.dart';
import 'screens/habit_details_page.dart';
import 'screens/settings_page.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications only on mobile platforms
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Send test notification after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        notificationService.showTestNotification();
      });
      debugPrint('✅ Notifications initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize notifications: $e');
    }
  } else {
    debugPrint('ℹ️ Skipping notification setup on ${Platform.operatingSystem}');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HabitsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            locale: const Locale('en', 'US'),
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('es', 'ES'),
            ],
            title: 'Habits Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => HomePage(),
              '/add-habits': (context) => AddHabitsPage(),
              '/habit-details': (context) => HabitDetailsPage(),
              '/settings': (context) => SettingsPage(),
            },
          );
        },
      ),
    );
  }
}
